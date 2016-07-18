defmodule Boltex do
  alias Boltex.Bolt

  def test(host, port, query) do
    {:ok, p}   = :gen_tcp.connect host, port, [active: false, mode: :binary, packet: :raw]

    :ok        = Bolt.handshake :gen_tcp, p
    :ok        = Bolt.init :gen_tcp, p

    Enum.map Bolt.run_statement(:gen_tcp, p, query), &IO.inspect/1
  end

end
