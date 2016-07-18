defmodule Boltex.Utils do
  def reduce_to_binary(enumerable, transform) do
    Enum.reduce enumerable, <<>>, fn(data, acc) -> acc <> transform.(data) end
  end

  def hex_encode(bytes) do
    for << i <- bytes >>, do: Integer.to_string(i, 16)
  end

  def hex_decode(hex_list) do
    for(hex <- hex_list, do: Integer.parse(hex, 16) |> elem(0))
    |> reduce_to_binary(&<<&1>>)
  end
end
