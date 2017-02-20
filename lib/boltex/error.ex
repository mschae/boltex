defmodule Boltex.Error do
  defexception [:message, :code, :connection_id, :function, :type]

  alias Boltex.Utils

  def exception(%{"message" => message, "code" => code}, pid, function) do
    %Boltex.Error{
      message:       message,
      code:          code,
      connection_id: get_id(pid),
      function:      function,
      type:          :cypher_error,
    }
  end

  def exception({:error, :closed}, pid, function) do
    %Boltex.Error{
      message:       "Port #{inspect pid} is closed",
      connection_id: get_id(pid),
      function:      function,
      type:          :connection_error,
    }
  end

  def exception(message, pid, function) do
    %Boltex.Error{
      message:       message_for(function, message),
      connection_id: get_id(pid),
      function:      function,
      type:          :protocol_error,
    }
  end

  defp message_for(:handshake, "HTTP") do
    """
    Handshake failed.
    The port expected a HTTP request.
    This happens when trying to Neo4J using the REST API Port (default: 7474)
    instead of the Bolt Port (default: 7687).
    """
  end
  defp message_for(:handshake, bin) when is_binary(bin) do
    """
    Handshake failed.
    Expected 01:00:00:00 as a result, received: #{Utils.hex_encode(bin)}.
    """
  end
  defp message_for(:hadshake, other) do
    """
    Handshake failed.
    Expected 01:00:00:00 as a result, received: #{inspect other}.
    """
  end
  defp message_for(nil, message) do
    """
    Unknown failure: #{inspect message}
    """
  end
  defp message_for(_function, {:error, error}) do
    case error |> :inet.format_error |> to_string do
      "unknown POSIX error" -> to_string error
      other                 -> other
    end
  end
  defp message_for(function, message) do
    """
    #{function}: Unknown failure: #{inspect message}
    """
  end

  defp get_id({:sslsocket, {:gen_tcp, port, _tls, _unused_yet}, _pid}) do
    get_id(port)
  end
  defp get_id(port) when is_port(port) do
    case Port.info(port, :id) do
      {:id, id} -> id
      nil       -> nil
    end
  end
  defp get_id(_), do: nil
end
