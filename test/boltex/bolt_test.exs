defmodule BoltexTest do
  use ExUnit.Case
  alias Boltex.Bolt
  doctest Boltex

  test "encodes big params correctly" do
    {:ok, port} = :gen_tcp.connect neo4j_host(), neo4j_port(), [active: false, mode: :binary, packet: :raw]
    :ok         = Bolt.handshake :gen_tcp, port
    :ok         = Bolt.init :gen_tcp, port, {"neo4j", "password"}


    query = """
      UNWIND {largeRange} as i
      RETURN i
    """

    params = %{largeRange: Enum.to_list(0..25_000)}

    [{:success, _} | records] = Bolt.run_statement(:gen_tcp, port, query, params, [recv_timeout: 100_000])
    numbers =
      records
      |> List.delete_at(-1)
      |> Enum.map(fn({:record, [number]}) -> number end)

    assert numbers == Enum.to_list(0..25_000)
  end

  def neo4j_host do
    case System.get_env("NEO4J_HOST") do
      nil  -> 'localhost'
      host -> String.to_charlist host
    end
  end

  def neo4j_port do
    case System.get_env("NEO4J_PORT") do
      nil  -> 7687
      port -> String.to_integer port
    end
  end
end
