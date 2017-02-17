defmodule Boltex.PackStream.EncodeError do
  @moduledoc """
  Represents an error when encoding data for the Boltex protocol.

  Shamelessly inspired by @devinus' Poison encoder.
  """

  defexception item: nil, message: nil

  def message(%{item: item, message: nil}) do
    "unable to encode value: #{inspect item}"
  end
end
