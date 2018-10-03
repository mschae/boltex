defmodule Boltex.Bolt do
  alias Boltex.Error
  alias Boltex.PackStream.Message
  require Logger

  @recv_timeout 10_000

  @hs_magic <<0x60, 0x60, 0xB0, 0x17>>

  @zero_chunk <<0x00, 0x00>>

  @max_version 2

  @summary ~w(success ignored failure)a

  @moduledoc """
  The Boltex.Bolt module handles the Bolt protocol specific steps (i.e.
  handshake, init) as well as sending and receiving messages and wrapping
  them in chunks.

  It abstracts transportation, expecting the transport layer to define
  `send/2` and `recv/3` analogous to `:gen_tcp`.

  ## Shared options

  Functions that allow for options accept these default options:

    * `recv_timeout`: The timeout for receiving a response from the Neo4J s
      server (default: #{@recv_timeout})
  """

  @doc """
  Initiates the handshake between the client and the server.

  ## Options

  See "Shared options" in the documentation of this module.
  """
  @spec handshake(atom(), port(), Keyword.t()) :: :ok | {:error, Boltex.Error.t()}
  def handshake(transport, port, options \\ []) do
    recv_timeout = get_recv_timeout(options)

    # Define version list. Should be a 4 integer list
    # Example: [1, 0, 0, 0]
    versions =
      ((@max_version..0
        |> Enum.into([])) ++ [0, 0, 0])
      |> Enum.take(4)

    Boltex.Logger.log_message(
      :client,
      :handshake,
      "#{inspect(@hs_magic, base: :hex)} #{inspect(versions)}"
    )

    data = @hs_magic <> Enum.into(versions, <<>>, fn version_ -> <<version_::32>> end)
    transport.send(port, data)

    case transport.recv(port, 4, recv_timeout) do
      {:ok, <<version::32>> = packet} when version <= @max_version ->
        Boltex.Logger.log_message(:server, :handshake, packet, :hex)
        Boltex.Logger.log_message(:server, :handshake, version)
        :ok

      {:ok, other} ->
        {:error, Error.exception(other, port, :handshake)}

      other ->
        {:error, Error.exception(other, port, :handshake)}
    end
  end

  @doc """
  Initialises the connection.

  Expects a transport module (i.e. `gen_tcp`) and a `Port`. Accepts
  authorisation params in the form of {username, password}.

  ## Options

  See "Shared options" in the documentation of this module.

  ## Examples

      iex> Boltex.Bolt.init :gen_tcp, port
      {:ok, info}

      iex> Boltex.Bolt.init :gen_tcp, port, {"username", "password"}
      {:ok, info}
  """
  @spec init(atom(), port(), tuple(), Keyword.t()) :: {:ok, any()} | {:error, Boltex.Error.t()}
  def init(transport, port, auth \\ {}, options \\ []) do
    send_message(transport, port, {:init, [auth]})

    case receive_data(transport, port, options) do
      {:success, info} ->
        {:ok, info}

      {:failure, response} ->
        {:error, Error.exception(response, port, :init)}

      other ->
        {:error, Error.exception(other, port, :init)}
    end
  end

  @doc false
  # Sends a message using the Bolt protocol and PackStream encoding.
  #
  # Message have to be in the form of {message_type, [data]}.
  @spec send_message(atom(), port(), Boltex.PackStream.Message.raw()) :: :ok | {:error, any()}
  def send_message(transport, port, message) do
    message
    |> Message.encode()
    |> (fn data -> transport.send(port, data) end).()
  end

  @doc """
  Runs a statement (most likely Cypher statement) and returns a list of the
  records and a summary (Act as as a RUN + PULL_ALL).

  Records are represented using PackStream's record data type. Their Elixir
  representation is a Keyword with the indexes `:sig` and `:fields`.

  ## Options

  See "Shared options" in the documentation of this module.

  ## Examples

      iex> Boltex.Bolt.run_statement("MATCH (n) RETURN n")
      [
        {:success, %{"fields" => ["n"]}},
        {:record, [sig: 1, fields: [1, "Example", "Labels", %{"some_attribute" => "some_value"}]]},
        {:success, %{"type" => "r"}}
      ]
  """
  @spec run_statement(atom(), port(), String.t(), map(), Keyword.t()) ::
          [
            Boltex.PackStream.Message.decoded()
          ]
          | Boltex.Error.t()
  def run_statement(transport, port, statement, params \\ %{}, options \\ []) do
    data = [statement, params]

    with :ok <- send_message(transport, port, {:run, data}),
         {:success, _} = data <- receive_data(transport, port, options),
         :ok <- send_message(transport, port, {:pull_all, []}),
         more_data <- receive_data(transport, port, options),
         more_data = List.wrap(more_data),
         {:success, _} <- List.last(more_data) do
      [data | more_data]
    else
      {:failure, map} ->
        Boltex.Error.exception(map, port, :run_statement)

      error = %Boltex.Error{} ->
        error

      error ->
        Boltex.Error.exception(error, port, :run_statement)
    end
  end

  @doc """
  Implementation of Bolt's ACK_FAILURE. It acknowledges a failure while keeping
  transactions alive.

  See http://boltprotocol.org/v1/#message-ack-failure

  ## Options

  See "Shared options" in the documentation of this module.
  """
  @spec ack_failure(atom(), port(), Keyword.t()) :: :ok | Boltex.Error.t()
  def ack_failure(transport, port, options \\ []) do
    send_message(transport, port, {:ack_failure, []})

    case receive_data(transport, port, options) do
      {:success, %{}} -> :ok
      error -> Boltex.Error.exception(error, port, :ack_failure)
    end
  end

  @doc """
  Implementation of Bolt's RESET message. It resets a session to a "clean"
  state.

  See http://boltprotocol.org/v1/#message-reset

  ## Options

  See "Shared options" in the documentation of this module.
  """
  @spec reset(atom(), port(), Keyword.t()) :: :ok | Boltex.Error.t()
  def reset(transport, port, options \\ []) do
    send_message(transport, port, {:reset, []})

    case receive_data(transport, port, options) do
      {:success, %{}} -> :ok
      error -> Boltex.Error.exception(error, port, :reset)
    end
  end

  @doc false
  # Receives data.
  #
  # This function is supposed to be called after a request to the server has been
  # made. It receives data chunks, mends them (if they were split between frames)
  # and decodes them using PackStream.
  #
  # When just a single message is received (i.e. to acknowledge a command), this
  # function returns a tuple with two items, the first being the signature and the
  # second being the message(s) itself. If a list of messages is received it will
  # return a list of the former.
  #
  # The same goes for the messages: If there was a single data point in a message
  # said data point will be returned by itself. If there were multiple data
  # points, the list will be returned.
  #
  # The signature is represented as one of the following:
  #
  # * `:success`
  # * `:record`
  # * `:ignored`
  # * `:failure`
  #
  # ## Options
  #
  # See "Shared options" in the documentation of this module.
  @spec receive_data(atom(), port(), Keyword.t(), list()) ::
          {atom(), Boltex.PackStream.value()} | {:error, any()}
  def receive_data(transport, port, options \\ [], previous \\ []) do
    with {:ok, data} <- do_receive_data(transport, port, options) do
      case Message.decode(data) do
        {:record, _} = data ->
          receive_data(transport, port, options, [data | previous])

        {status, _} = data when status in @summary and previous == [] ->
          data

        {status, _} = data when status in @summary ->
          Enum.reverse([data | previous])

        other ->
          {:error, Error.exception(other, port, :receive_data)}
      end
    else
      other ->
        # Should be the line below to have a cleaner typespec
        # Keep the old return value to not break usage
        # {:error, Error.exception(other, port, :receive_data)}
        Error.exception(other, port, :receive_data)
    end
  end

  @spec do_receive_data(atom(), port(), Keyword.t()) :: {:ok, binary()}
  defp do_receive_data(transport, port, options) do
    recv_timeout = get_recv_timeout(options)

    case transport.recv(port, 2, recv_timeout) do
      {:ok, <<chunk_size::16>>} ->
        do_receive_data_(transport, port, chunk_size, options, <<>>)

      other ->
        other
    end
  end

  @spec do_receive_data_(atom(), port(), integer(), Keyword.t(), binary()) :: {:ok, binary()}
  defp do_receive_data_(transport, port, chunk_size, options, old_data) do
    recv_timeout = get_recv_timeout(options)

    with {:ok, data} <- transport.recv(port, chunk_size, recv_timeout),
         {:ok, marker} <- transport.recv(port, 2, recv_timeout) do
      case marker do
        @zero_chunk ->
          {:ok, old_data <> data}

        <<chunk_size::16>> ->
          data = old_data <> data
          do_receive_data_(transport, port, chunk_size, options, data)
      end
    else
      other ->
        Error.exception(other, port, :recv)
    end
  end

  @spec get_recv_timeout(Keyword.t()) :: integer()
  defp get_recv_timeout(options) do
    Keyword.get(options, :recv_timeout, @recv_timeout)
  end
end
