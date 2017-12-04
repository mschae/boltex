defmodule Boltex do
  @moduledoc """
  Elixir library for using the Neo4J Bolt Protocol.

  It supports de- and encoding of Boltex binaries and sending and receiving
  of data using the Bolt protocol.
  """

  alias Boltex.Bolt

  def test(host, port, query, params \\ %{}, auth \\ {}) do
    {:ok, p}   = :gen_tcp.connect host, port, [active: false, mode: :binary, packet: :raw]

    :ok         = Bolt.handshake :gen_tcp, p
    {:ok, _info} = Bolt.init :gen_tcp, p, auth

    Bolt.run_statement(:gen_tcp, p, query, params)
  end
end
