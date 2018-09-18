defmodule Boltex.PackStream.Message do
  @moduledoc """
  Manage the message encoding and decoding.

  Message encoding / decoding is the first step of encoding / decoding.
  The next step is the message data encoding /decoding (which is handled by packstream.ex)
  """
  alias Boltex.PackStream.Message.Encoder
  alias Boltex.PackStream.Message.Decoder

  @doc """
  Encode a message
  """
  def encode(message) do
    Encoder.encode(message)
  end

  @doc """
  Decode a message
  """
  def decode(message) do
    Decoder.decode(message)
  end
end
