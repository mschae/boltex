defmodule Boltex.PackStreamTest do
  use ExUnit.Case

  alias Boltex.{Utils, PackStream}

  # A lot of the examples have been taken from
  # https://github.com/neo4j/neo4j-python-driver/blob/1.1/neo4j/v1/packstream.py
  # """
  #
  defmodule TestStruct do
    defstruct foo: "bar"
  end

  ##
  # Encoding

  doctest Boltex.PackStream

  test "encodes null" do
    assert PackStream.encode(nil) == <<0xC0>>
  end

  test "encodes boolean" do
    assert PackStream.encode(true)   ==  <<0xC3>>
    assert PackStream.encode(false)  ==  <<0xC2>>
  end

  test "encodes atom" do
    assert PackStream.encode(:hello) ==  <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>
  end

  test "encodes integer" do
    assert PackStream.encode(0)   == << 0x00 >>
    assert PackStream.encode(42)  == << 0x2A >>
    assert PackStream.encode(-42) == << 0xC8, 0xD6 >>
    assert PackStream.encode(420) == << 0xC9, 0x01, 0xA4 >>
    assert PackStream.encode(33_000) == << 0xCA, 0x00, 0x00, 0x80, 0xE8 >>
    assert PackStream.encode(2_150_000_000) == << 0xCB, 0x00, 0x00, 0x00, 0x00, 0x80, 0x26, 0x65, 0x80 >>
  end

  test "encodes float" do
    assert PackStream.encode(+1.1) == << 0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A >>
    assert PackStream.encode(-1.1) == << 0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A >>
  end

  test "encodes string" do
    assert PackStream.encode("")      == << 0x80 >>
    assert PackStream.encode("Short") == <<0x85, 0x53, 0x68, 0x6F, 0x72, 0x74>>

    long_8 = "This is a räther löng string" # 30 bytes due to umlauts
    assert <<0xD0, 0x1E, _ :: binary-size(30)>> = PackStream.encode(long_8)

    long_16 =
      """
      For encoded string containing fewer than 16 bytes, including empty strings,
      the marker byte should contain the high-order nibble `1000` followed by a
      low-order nibble containing the size. The encoded data then immediately
      follows the marker.

      For encoded string containing 16 bytes or more, the marker 0xD0, 0xD1 or
      0xD2 should be used, depending on scale. This marker is followed by the
      size and the UTF-8 encoded data.
      """
    assert <<0xD1, 0x01, 0xA5, _ :: binary-size(421)>> = PackStream.encode(long_16)

    long_32 = String.duplicate("a", 66_000)
    assert <<0xD2, 66_000 :: 32, _ :: binary-size(66_000)>> = PackStream.encode(long_32)
  end

  test "encodes list" do
    assert PackStream.encode([]) == <<0x90>>
    long_list = Stream.repeatedly(fn -> "a" end) |> Enum.take(66_000)
    assert << 0xD6, 66_000 :: 32, _ :: binary-size(132_000) >> = PackStream.encode(long_list)
  end

  test "encodes map" do
    assert PackStream.encode(%{}) == <<0xA0>>
  end

  test "encodes a struct" do
    assert PackStream.encode(%TestStruct{foo: "bar"}) == PackStream.encode(%{foo: "bar"})
  end

  test "raises an error when trying to encode something we don't know" do
    assert_raise Boltex.PackStream.EncodeError, fn ->
      PackStream.encode({:tuple})
    end
  end

  ##
  # Decoding

  test "decodes null" do
    assert PackStream.decode(<<0xC0>>) == [nil]
  end

  test "decodes boolean" do
    assert PackStream.decode(<<0xC3>>) == [true]
    assert PackStream.decode(<<0xC2>>) == [false]
  end

  test "decodes floats" do
    positive = ~w(C1 3F F1 99 99 99 99 99 9A) |> Utils.hex_decode
    negative = ~w(C1 BF F1 99 99 99 99 99 9A) |> Utils.hex_decode

    assert PackStream.decode(positive) == [1.1]
    assert PackStream.decode(negative) == [-1.1]
  end

  test "decodes integers" do
    assert PackStream.decode(<<0x2A>>)                            == [42]
    assert PackStream.decode(<<0xC8, 0x2A>>)                      == [42]
    assert PackStream.decode(<<0xC9, 0, 0x2A>>)                   == [42]
    assert PackStream.decode(<<0xCA, 0, 0, 0, 0x2A>>)             == [42]
    assert PackStream.decode(<<0xCB, 0, 0, 0, 0, 0, 0, 0, 0x2A>>) == [42]
  end

  test "decodes strings" do
    longstr =
      ~w(D0 1A 61 62  63 64 65 66  67 68 69 6A  6B 6C 6D 6E 6F 70 71 72  73 74 75 76  77 78 79 7A)
      |> Utils.hex_decode

    specialcharstr =
      ~w(D0 18 45 6E  20 C3 A5 20  66 6C C3 B6  74 20 C3 B6 76 65 72 20  C3 A4 6E 67  65 6E)
      |> Utils.hex_decode


    assert PackStream.decode(<<0x80>>)       == [""]
    assert PackStream.decode(<<0x81, 0x61>>) == ["a"]
    assert PackStream.decode(longstr)        == ["abcdefghijklmnopqrstuvwxyz"]
    assert PackStream.decode(specialcharstr) == ["En å flöt över ängen"]
  end

  test "decodes lists" do
    longlist =
      ~w(D4 14 01 02 03 04 05 06  07 08 09 00)
      |> Utils.hex_decode

    assert PackStream.decode(<<0x90>>)                   == [[]]
    assert PackStream.decode(<<0x93, 0x01, 0x02, 0x03>>) == [[1, 2, 3]]
    assert PackStream.decode(longlist)                   == [[1, 2, 3, 4, 5, 6, 7, 8, 9, 0]]
    assert PackStream.decode(<<0xD7, 0x01, 0x02, 0xDF>>) == [[1, 2]]
  end

  test "decodes maps" do
    big_map =
      ~w(
      D8 10 81 61  01 81 62 01  81 63 03 81  64 04 81 65
      05 81 66 06  81 67 07 81  68 08 81 69  09 81 6A 00
      81 6B 01 81  6C 02 81 6D  03 81 6E 04  81 6F 05 81
      70 06
      )
      |> Utils.hex_decode

    assert PackStream.decode(<<0xA0>>) == [%{}]
    assert PackStream.decode(<<0xA1, 0x81, 0x61, 0x01>>) == [%{"a" => 1}]
    assert PackStream.decode(<<0xAB, 0x81, 0x61, 0x01>>) == [%{"a" => 1}]
    assert PackStream.decode(<<0xDB, 0x81, 0x61, 0x01, 0xDF>>) == [%{"a" => 1}]
    assert PackStream.decode(big_map) == [%{"a" => 1,"b" => 1,"c" => 3,"d" => 4,"e" => 5,"f" => 6,"g" => 7,"h" => 8,"i" => 9,"j" => 0,"k" => 1,"l" => 2,"m" => 3,"n" => 4,"o" => 5,"p" => 6}]

  end

  test "decodes big maps" do
  end
end
