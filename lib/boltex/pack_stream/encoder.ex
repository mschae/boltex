alias Boltex.PackStream.Message.{AckFailure, DiscardAll, Init, PullAll, Reset, Run}

defprotocol Boltex.PackStream.Encoder do
  @doc "Encodes an item to its binary PackStream Representation"

  @fallback_to_any true

  def encode(entitiy)
end

defimpl Boltex.PackStream.Encoder, for: Atom do
  @null_marker 0xC0
  @true_marker 0xC3
  @false_marker 0xC2

  def encode(nil), do: <<@null_marker>>
  def encode(true), do: <<@true_marker>>
  def encode(false), do: <<@false_marker>>

  def encode(other) when is_atom(other) do
    other
    |> Atom.to_string()
    |> Boltex.PackStream.Encoder.encode()
  end
end

defimpl Boltex.PackStream.Encoder, for: Integer do
  @int8_marker 0xC8
  @int16_marker 0xC9
  @int32_marker 0xCA
  @int64_marker 0xCB

  @int8 -127..-17
  @int16_low -32_768..-129
  @int16_high 128..32_767
  @int32_low -2_147_483_648..-32_769
  @int32_high 32_768..2_147_483_647
  @int64_low -9_223_372_036_854_775_808..-2_147_483_649
  @int64_high 2_147_483_648..9_223_372_036_854_775_807

  def encode(integer) when integer in -16..127 do
    <<integer>>
  end

  def encode(integer) when integer in @int8 do
    <<@int8_marker, integer>>
  end

  def encode(integer) when integer in @int16_low or integer in @int16_high do
    <<@int16_marker, integer::16>>
  end

  def encode(integer) when integer in @int32_low or integer in @int32_high do
    <<@int32_marker, integer::32>>
  end

  def encode(integer) when integer in @int64_low or integer in @int64_high do
    <<@int64_marker, integer::64>>
  end
end

defimpl Boltex.PackStream.Encoder, for: Float do
  @float_marker 0xC1

  def encode(number) do
    <<@float_marker, number::float>>
  end
end

defimpl Boltex.PackStream.Encoder, for: BitString do
  @tiny_bitstring_marker 0x8
  @bitstring8_marker 0xD0
  @bitstring16_marker 0xD1
  @bitstring32_marker 0xD2

  def encode(string), do: do_encode(string, byte_size(string))

  defp do_encode(string, size) when size <= 15 do
    <<@tiny_bitstring_marker::4, size::4>> <> string
  end

  defp do_encode(string, size) when size <= 255 do
    <<@bitstring8_marker, size::8>> <> string
  end

  defp do_encode(string, size) when size <= 65_535 do
    <<@bitstring16_marker, size::16>> <> string
  end

  defp do_encode(string, size) when size <= 4_294_967_295 do
    <<@bitstring32_marker, size::32>> <> string
  end
end

defimpl Boltex.PackStream.Encoder, for: List do
  @tiny_list_marker 0x9
  @list8_marker 0xD4
  @list16_marker 0xD5
  @list32_marker 0xD6

  def encode(list) do
    binary = Enum.map_join(list, &Boltex.PackStream.Encoder.encode/1)

    do_encode(binary, length(list))
  end

  defp do_encode(binary, list_size) when list_size <= 15 do
    <<@tiny_list_marker::4, list_size::4>> <> binary
  end

  defp do_encode(binary, list_size) when list_size <= 255 do
    <<@list8_marker, list_size::8>> <> binary
  end

  defp do_encode(binary, list_size) when list_size <= 65_535 do
    <<@list16_marker, list_size::16>> <> binary
  end

  defp do_encode(binary, list_size) when list_size <= 4_294_967_295 do
    <<@list32_marker, list_size::32>> <> binary
  end
end

defimpl Boltex.PackStream.Encoder, for: Map do
  @tiny_map_marker 0xA
  @map8_marker 0xD8
  @map16_marker 0xD9
  @map32_marker 0xDA

  def encode(map) do
    do_encode(map, map_size(map))
  end

  defp do_encode(map, size) when size <= 15 do
    <<@tiny_map_marker::4, size::4>> <> encode_kv(map)
  end

  defp do_encode(map, size) when size <= 255 do
    <<@map8_marker, size::8>> <> encode_kv(map)
  end

  defp do_encode(map, size) when size <= 65_535 do
    <<@map16_marker, size::16>> <> encode_kv(map)
  end

  defp do_encode(map, size) when size <= 4_294_967_295 do
    <<@map32_marker, size::32>> <> encode_kv(map)
  end

  defp encode_kv(map) do
    Boltex.Utils.reduce_to_binary(map, &do_reduce_kv/1)
  end

  defp do_reduce_kv({key, value}) do
    Boltex.PackStream.Encoder.encode(key) <> Boltex.PackStream.Encoder.encode(value)
  end
end

defimpl Boltex.PackStream.Encoder, for: [AckFailure, DiscardAll, Init, PullAll, Reset, Run] do
  @max_chunk_size 65_535
  @end_marker <<0x00, 0x00>>

  def encode(data) do
    Boltex.PackStream.Encoder.encode({@for.signature, @for.list_data(data)})
    |> generate_chunks()
  end

  defp generate_chunks(data, chunks \\ [])

  defp generate_chunks(data, chunks) when byte_size(data) > @max_chunk_size do
    <<chunk::binary-@max_chunk_size, rest::binary>> = data
    generate_chunks(rest, [format_chunk(chunk) | chunks])
  end

  defp generate_chunks(<<>>, chunks) do
    [@end_marker | chunks]
    |> Enum.reverse()
    |> Enum.join()
  end

  defp generate_chunks(data, chunks) do
    generate_chunks(<<>>, [format_chunk(data) | chunks])
  end

  defp format_chunk(chunk) do
    <<byte_size(chunk)::16>> <> chunk
  end
end

defimpl Boltex.PackStream.Encoder, for: Any do
  @tiny_struct_marker 0xB
  @struct8_marker 0xDC
  @struct16_marker 0xDD

  @valid_signatures 0..127

  def encode({signature, %{__struct__: _} = data}) when signature in @valid_signatures do
    do_encode(data, signature)
  end

  def encode({signature, data}) when signature in @valid_signatures and is_list(data) do
    do_encode(data, signature)
  end

  def encode(item) do
    raise Boltex.PackStream.EncodeError, item: item
  end

  # Unordered structs
  # For this kind of structs, a Map is provided
  defp do_encode(map, signature) when is_map(map) and map_size(map) < 16 do
    <<@tiny_struct_marker::4, map_size(map)::4, signature>> <> encode_struct_map(map)
  end

  defp do_encode(map, signature) when is_map(map) and map_size(map) < 256 do
    <<@struct8_marker::8, map_size(map)::8, signature>> <> encode_struct_map(map)
  end

  defp do_encode(map, signature) when is_map(map) and map_size(map) < 65_535 do
    <<@struct16_marker::8, map_size(map)::16, signature>> <> encode_struct_map(map)
  end

  # Ordered structs
  # For this kind of structs, a List is provided
  # Typically, message will be ordered struct
  defp do_encode(list, signature) when is_list(list) and length(list) < 16 do
    <<@tiny_struct_marker::4, length(list)::4, signature>> <> encode_struct_list(list)
  end

  defp do_encode(list, signature) when is_list(list) and length(list) < 256 do
    <<@struct8_marker::8, length(list)::8, signature>> <> encode_struct_list(list)
  end

  defp do_encode(list, signature) when is_list(list) and length(list) < 65_535 do
    <<@struct16_marker::8, length(list)::16, signature>> <> encode_struct_list(list)
  end

  defp encode_struct_map(data) do
    data
    |> Map.from_struct()
    |> Boltex.PackStream.Encoder.encode()
  end

  defp encode_struct_list(data) do
    data
    |> Enum.map_join("", &Boltex.PackStream.Encoder.encode/1)
  end
end
