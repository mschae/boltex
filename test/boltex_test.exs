defmodule BoltexTest do
  use ExUnit.Case

  test "it works" do
    uri = Boltex.IntegrationCase.neo4j_uri
    Boltex.test uri.host, uri.port, "RETURN 1 as num", %{}, uri.userinfo
  end
end
