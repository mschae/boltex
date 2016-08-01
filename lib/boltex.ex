defmodule Boltex do
  alias Boltex.Bolt

  def test(host, port, query, params \\ %{}, auth \\ nil) do
    {:ok, p}   = :gen_tcp.connect host, port, [active: false, mode: :binary, packet: :raw]

    :ok        = Bolt.handshake :gen_tcp, p
    :ok        = Bolt.init :gen_tcp, p, params

    IO.inspect Bolt.run_statement(:gen_tcp, p, query)
  end

end
