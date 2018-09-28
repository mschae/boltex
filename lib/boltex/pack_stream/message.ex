defmodule Boltex.PackStream.Message do
  @moduledoc """
  Manage the message encoding and decoding.

  Message encoding / decoding is the first step of encoding / decoding.
  The next step is the message data encoding /decoding (which is handled by packstream.ex)
  """
  alias Boltex.PackStream.Message.Encoder
  alias Boltex.PackStream.Message.Decoder

  @type in_signature :: :failure | :ignored | :record | :success
  @type out_signature :: :init | :run | :ack_failure | :discard_all | :pull_all | :reset
  @type raw :: {out_signature, list()}
  @type decoded :: {in_signature(), any()}
  @type encoded :: <<_::16, _::_*8>>

  @doc """
  Encode a message
  """
  @spec encode({Boltex.PackStream.Message.out_signature(), list()}) ::
          Boltex.PackStream.Message.encoded()
  def encode(message) do
    Encoder.encode(message)
  end

  @doc """
  Decode a message
  """
  @spec decode(Boltex.PackStream.Message.encoded()) :: Boltex.PackStream.Message.decoded()
  def decode(message) do
    Decoder.decode(message)
  end
end
