defmodule BoltexTest do
  use Boltex.IntegrationCase
  alias Boltex.Bolt

  doctest Boltex

  test "works for small queries", %{port: port} do
    query = """
      UNWIND {largeRange} as i
      RETURN i
    """

    params = %{largeRange: Enum.to_list(0..100)}

    [{:success, _} | records] = Bolt.run_statement :gen_tcp, port, query, params

    numbers =
      records
      |> List.delete_at(-1)
      |> Enum.map(fn({:record, [number]}) -> number end)

    assert numbers == Enum.to_list(0..100)
  end

  test "works for big queries", %{port: port} do
    query = """
      UNWIND {largeRange} as i
      RETURN i
    """

    params = %{largeRange: Enum.to_list(0..25_000)}

    [{:success, _} | records] = Bolt.run_statement :gen_tcp, port, query, params

    numbers =
      records
      |> List.delete_at(-1)
      |> Enum.map(fn({:record, [number]}) -> number end)

    assert numbers == Enum.to_list(0..25_000)
  end

  test "returns errors for wrong cypher queris", %{port: port} do
    assert %Boltex.Error{type: :cypher_error} = Bolt.run_statement :gen_tcp, port, "What?"
  end

  test "allows to recover from error", %{port: port} do
    assert %Boltex.Error{type: :cypher_error} = Bolt.run_statement :gen_tcp, port, "What?"
    assert :ok                                = Bolt.ack_failure :gen_tcp, port, []
    assert [{:success, _} | _]                = Bolt.run_statement :gen_tcp, port, "RETURN 1 as num"
  end

  test "returns proper error when using a bad session", %{port: port} do
    assert %Boltex.Error{type: :cypher_error} = Bolt.run_statement :gen_tcp, port, "What?"
    error = Bolt.run_statement :gen_tcp, port, "RETURN 1 as num"

    assert %Boltex.Error{} = error
    assert error.message   =~ ~r/'ACK_FAILURE'/
  end
end
