defmodule Boltex.PackStreamTest do
  use ExUnit.Case, async: true

  alias Boltex.{Utils, PackStream}
  alias Boltex.PackStream.Message.{AckFailure, DiscardAll, Init, PullAll, Reset, Run}

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
    assert PackStream.encode(true) == <<0xC3>>
    assert PackStream.encode(false) == <<0xC2>>
  end

  test "encodes atom" do
    assert PackStream.encode(:hello) == <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>
  end

  test "encodes integer" do
    assert PackStream.encode(0) == <<0x00>>
    assert PackStream.encode(42) == <<0x2A>>
    assert PackStream.encode(-42) == <<0xC8, 0xD6>>
    assert PackStream.encode(420) == <<0xC9, 0x01, 0xA4>>
    assert PackStream.encode(33_000) == <<0xCA, 0x00, 0x00, 0x80, 0xE8>>

    assert PackStream.encode(2_150_000_000) ==
             <<0xCB, 0x00, 0x00, 0x00, 0x00, 0x80, 0x26, 0x65, 0x80>>
  end

  test "encodes float" do
    assert PackStream.encode(+1.1) == <<0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>
    assert PackStream.encode(-1.1) == <<0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>
  end

  test "encodes string" do
    assert PackStream.encode("") == <<0x80>>
    assert PackStream.encode("Short") == <<0x85, 0x53, 0x68, 0x6F, 0x72, 0x74>>

    # 30 bytes due to umlauts
    long_8 = "This is a räther löng string"
    assert <<0xD0, 0x1E, _::binary-size(30)>> = PackStream.encode(long_8)

    long_16 = """
    For encoded string containing fewer than 16 bytes, including empty strings,
    the marker byte should contain the high-order nibble `1000` followed by a
    low-order nibble containing the size. The encoded data then immediately
    follows the marker.

    For encoded string containing 16 bytes or more, the marker 0xD0, 0xD1 or
    0xD2 should be used, depending on scale. This marker is followed by the
    size and the UTF-8 encoded data.
    """

    assert <<0xD1, 0x01, 0xA5, _::binary-size(421)>> = PackStream.encode(long_16)

    long_32 = String.duplicate("a", 66_000)
    assert <<0xD2, 66_000::32, _::binary-size(66_000)>> = PackStream.encode(long_32)
  end

  test "encodes list" do
    assert PackStream.encode([]) == <<0x90>>

    list_8 = Stream.repeatedly(fn -> "a" end) |> Enum.take(16)
    assert <<0xD4, 16::8, _::binary-size(32)>> = PackStream.encode(list_8)

    list_16 = Stream.repeatedly(fn -> "a" end) |> Enum.take(256)
    assert <<0xD5, 256::16, _::binary-size(512)>> = PackStream.encode(list_16)

    list_32 = Stream.repeatedly(fn -> "a" end) |> Enum.take(66_000)
    assert <<0xD6, 66_000::32, _::binary-size(132_000)>> = PackStream.encode(list_32)
  end

  test "encodes map" do
    assert PackStream.encode(%{}) == <<0xA0>>

    map_8 = 1..16 |> Enum.map(&{&1, "a"}) |> Map.new()
    assert <<0xD8, 16::8>> <> _rest = PackStream.encode(map_8)

    map_16 = 1..256 |> Enum.map(&{&1, "a"}) |> Map.new()
    assert <<0xD9, 256::16>> <> _rest = PackStream.encode(map_16)

    map_32 = 1..66_000 |> Enum.map(&{&1, "a"}) |> Map.new()
    assert <<0xDA, 66_000::32>> <> _rest = PackStream.encode(map_32)
  end

  test "encodes a struct" do
    # Unordered struct
    assert <<0xB2, 0x1, 0xA1, 0x83, 0x66, 0x6F, 0x6F, 0x83, 0x62, 0x61, 0x72>> =
             PackStream.encode({0x01, %TestStruct{foo: "bar"}})

    # Ordered struct
    assert <<0xB2, 0x1, 0x85, 0x66, 0x69, 0x72, 0x73, 0x74, 0x86, 0x73, 0x65, 0x63, 0x6F, 0x6E,
             0x64>> = PackStream.encode({0x01, ["first", "second"]})

    assert <<0xDC, 0x6F, _::binary>> = PackStream.encode({0x01, Enum.into(1..111, [])})
    assert <<0xDD, 0x1, 0x4D, _::binary>> = PackStream.encode({0x01, Enum.into(1..333, [])})

    assert_raise Boltex.PackStream.EncodeError, ~r/^unable to encode value: /i, fn ->
      PackStream.encode({128, []})
    end

    assert_raise Boltex.PackStream.EncodeError, ~r/^unable to encode value: /i, fn ->
      PackStream.encode({-1, []})
    end

    assert_raise Boltex.PackStream.EncodeError, ~r/^unable to encode value: /i, fn ->
      PackStream.encode({"a", []})
    end
  end

  describe "Encodes messages:" do
    test "ack_failure" do
      assert <<0x0, 0x2, 0xB0, 0xE, 0x0, 0x0>> = PackStream.encode(%AckFailure{})
    end

    test "discard_all" do
      assert <<0x0, 0x2, 0xB0, 0x2F, 0x0, 0x0>> = PackStream.encode(%DiscardAll{})
    end

    test "init" do
      assert <<0x0, 0x10, 0xB2, 0x1, 0x8C, 0x42, 0x6F, 0x6C, 0x74, 0x65, 0x78, 0x2F, 0x30, 0x2E,
               0x34, 0x2E, 0x30, 0xA0, 0x0, 0x0>> = PackStream.encode(%Init{})

      init = %Init{auth_token: %{scheme: "basic", principal: "neo4j", credentials: "password"}}

      assert <<0x0, 0x42, 0xB2, 0x1, 0x8C, 0x42, 0x6F, 0x6C, 0x74, 0x65, 0x78, 0x2F, 0x30, 0x2E,
               0x34, 0x2E, 0x30, 0xA3, 0x8B, 0x63, 0x72, 0x65, 0x64, 0x65, 0x6E, 0x74, 0x69, 0x61,
               0x6C, 0x73, 0x88, 0x70, 0x61, 0x73, 0x73, 0x77, 0x6F, 0x72, 0x64, 0x89, 0x70, 0x72,
               0x69, 0x6E, 0x63, 0x69, 0x70, 0x61, 0x6C, 0x85, 0x6E, 0x65, 0x6F, 0x34, 0x6A, 0x86,
               0x73, 0x63, 0x68, 0x65, 0x6D, 0x65, 0x85, 0x62, 0x61, 0x73, 0x69, 0x63, 0x0,
               0x0>> = PackStream.encode(init)
    end

    test "pull_all" do
      assert <<0x0, 0x2, 0xB0, 0x3F, 0x0, 0x0>> = PackStream.encode(%PullAll{})
    end

    test "reset" do
      assert <<0x0, 0x2, 0xB0, 0xF, 0x0, 0x0>> = PackStream.encode(%Reset{})
    end

    test "run" do
      run_without_params = %Run{statement: "RETURN 1 AS num", parameters: %{}}

      assert <<0x0, 0x13, 0xB2, 0x10, 0x8F, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x31, 0x20,
               0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0x0,
               0x0>> = PackStream.encode(run_without_params)

      run_with_params = %Run{statement: "RETURN {num} AS num", parameters: %{num: 5}}

      <<0x0, 0x1D, 0xB2, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x7B, 0x6E,
        0x75, 0x6D, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA1, 0x83, 0x6E, 0x75, 0x6D,
        0x5, 0x0, 0x0>> = PackStream.encode(run_with_params)

      # IO.puts(inspect(res, base: :hex))
    end
  end

  test "raises an error when trying to encode something we don't know" do
    assert_raise Boltex.PackStream.EncodeError, "unable to encode value: {:tuple}", fn ->
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
    positive = ~w(C1 3F F1 99 99 99 99 99 9A) |> Utils.hex_decode()
    negative = ~w(C1 BF F1 99 99 99 99 99 9A) |> Utils.hex_decode()

    assert PackStream.decode(positive) == [1.1]
    assert PackStream.decode(negative) == [-1.1]
  end

  test "decodes integers" do
    assert PackStream.decode(<<0x2A>>) == [42]
    assert PackStream.decode(<<0xC8, 0x2A>>) == [42]
    assert PackStream.decode(<<0xC9, 0, 0x2A>>) == [42]
    assert PackStream.decode(<<0xCA, 0, 0, 0, 0x2A>>) == [42]
    assert PackStream.decode(<<0xCB, 0, 0, 0, 0, 0, 0, 0, 0x2A>>) == [42]
  end

  test "decodes negatiev integers" do
    assert PackStream.decode(<<0xC8, 0xD6>>) == [-42]
  end

  test "decodes strings" do
    longstr =
      ~w(D0 1A 61 62  63 64 65 66  67 68 69 6A  6B 6C 6D 6E 6F 70 71 72  73 74 75 76  77 78 79 7A)
      |> Utils.hex_decode()

    specialcharstr =
      ~w(D0 18 45 6E  20 C3 A5 20  66 6C C3 B6  74 20 C3 B6 76 65 72 20  C3 A4 6E 67  65 6E)
      |> Utils.hex_decode()

    assert PackStream.decode(<<0x80>>) == [""]
    assert PackStream.decode(<<0x81, 0x61>>) == ["a"]
    assert PackStream.decode(longstr) == ["abcdefghijklmnopqrstuvwxyz"]
    assert PackStream.decode(specialcharstr) == ["En å flöt över ängen"]
  end

  test "decodes lists" do
    assert PackStream.decode(<<0x90>>) == [[]]
    assert PackStream.decode(<<0x93, 0x01, 0x02, 0x03>>) == [[1, 2, 3]]

    list_8 = <<0xD4, 16::8>> <> (1..16 |> Enum.map(&PackStream.encode/1) |> Enum.join())
    assert PackStream.decode(list_8) == [1..16 |> Enum.to_list()]

    list_16 = <<0xD5, 256::16>> <> (1..256 |> Enum.map(&PackStream.encode/1) |> Enum.join())
    assert PackStream.decode(list_16) == [1..256 |> Enum.to_list()]

    list_32 = <<0xD6, 66_000::32>> <> (1..66_000 |> Enum.map(&PackStream.encode/1) |> Enum.join())
    assert PackStream.decode(list_32) == [1..66_000 |> Enum.to_list()]

    ending_0_list = <<0x93, 0x91, 0x1, 0x92, 0x2, 0x0, 0x0>>
    assert PackStream.decode(ending_0_list) == [[[1], [2, 0], 0]]
  end

  test "decodes maps" do
    assert PackStream.decode(<<0xA0>>) == [%{}]
    assert PackStream.decode(<<0xA1, 0x81, 0x61, 0x01>>) == [%{"a" => 1}]
    assert PackStream.decode(<<0xAB, 0x81, 0x61, 0x01>>) == [%{"a" => 1}]

    map_8 =
      <<0xD8, 16::8>> <>
        (1..16
         |> Enum.map(fn i -> PackStream.encode("#{i}") <> <<1>> end)
         |> Enum.join())

    assert PackStream.decode(map_8) |> List.first() |> map_size == 16

    map_16 =
      <<0xD9, 256::16>> <>
        (1..256
         |> Enum.map(fn i -> PackStream.encode("#{i}") <> <<1>> end)
         |> Enum.join())

    assert PackStream.decode(map_16) |> List.first() |> map_size == 256

    map_32 =
      <<0xDA, 66_000::32>> <>
        (1..66_000
         |> Enum.map(fn i -> PackStream.encode("#{i}") <> <<1>> end)
         |> Enum.join())

    assert PackStream.decode(map_32) |> List.first() |> map_size == 66_000
  end

  test "decodes structs" do
    assert PackStream.decode(<<0xB0, 0x01>>) == [[sig: 1, fields: []]]
    assert PackStream.decode(<<0xB1, 0x01, 0x01>>) == [[sig: 1, fields: [1]]]

    struct_8 = <<0xDC, 16::8, 0x02>> <> (1..16 |> Enum.map(&PackStream.encode/1) |> Enum.join())
    assert PackStream.decode(struct_8) == [[sig: 2, fields: Enum.to_list(1..16)]]

    struct_16 =
      <<0xDD, 256::16, 0x03>> <> (1..256 |> Enum.map(&PackStream.encode/1) |> Enum.join())

    assert PackStream.decode(struct_16) == [[sig: 3, fields: Enum.to_list(1..256)]]
  end
end
