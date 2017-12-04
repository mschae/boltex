defmodule Boltex.IntegrationCase do
  use ExUnit.CaseTemplate

  alias Boltex.Bolt

  setup do
    uri          = neo4j_uri()
    port_opts    = [active: false, mode: :binary, packet: :raw]
    {:ok, port}  = :gen_tcp.connect uri.host, uri.port, port_opts
    :ok          = Bolt.handshake :gen_tcp, port
    {:ok, _info} = Bolt.init :gen_tcp, port, uri.userinfo

    on_exit fn ->
      :gen_tcp.close port
    end

    {:ok, port: port}
  end

  def neo4j_uri do
    "bolt://neo4j:password@localhost:7687"
    |> URI.merge(System.get_env("NEO4J_TEST_URL") || "")
    |> URI.parse()
    |> Map.update!(:host, &String.to_charlist/1)
    |> Map.update!(:userinfo, fn
      nil ->
        {}

      userinfo ->
        userinfo
        |> String.split(":")
        |> List.to_tuple
    end)
  end
end
