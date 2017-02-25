defmodule Boltex.UtilsTest do
  use ExUnit.Case

  alias Boltex.Utils

  test "encodes bytes to hex" do
    assert ~w(7B 7C) == Utils.hex_encode(<<123, 124>>)
  end
end
