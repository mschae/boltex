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
end
