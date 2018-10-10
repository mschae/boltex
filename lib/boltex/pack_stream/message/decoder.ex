defmodule Boltex.PackStream.Message.Decoder do
  @moduledoc false

  @tiny_struct_marker 0xB

  @success_signature 0x70
  @failure_signature 0x7F
  @record_signature 0x71
  @ignored_signature 0x7E

  @doc """
  Decode SUCCESS message
  """
  @spec decode(Boltex.PackStream.Message.encoded()) :: Boltex.PackStream.Message.decoded()
  def decode(<<@tiny_struct_marker::4, nb_entries::4, @success_signature, data::binary>>) do
    build_response(:success, data, nb_entries)
  end

  @doc """
  Decode FAILURE message
  """
  def decode(<<@tiny_struct_marker::4, nb_entries::4, @failure_signature, data::binary>>) do
    build_response(:failure, data, nb_entries)
  end

  @doc """
  Decode RECORD message
  """
  def decode(<<@tiny_struct_marker::4, nb_entries::4, @record_signature, data::binary>>) do
    build_response(:record, data, nb_entries)
  end

  @doc """
  Decode IGNORED message
  """
  def decode(<<@tiny_struct_marker::4, nb_entries::4, @ignored_signature, data::binary>>) do
    build_response(:ignored, data, nb_entries)
  end

  @spec build_response(Boltex.PackStream.Message.in_signature(), any(), integer()) ::
          Boltex.PackStream.Message.decoded()
  defp build_response(message_type, data, nb_entries) do
    Boltex.Logger.log_message(:server, message_type, data, :hex)

    response =
      case Boltex.PackStream.decode(data) do
        response when nb_entries == 1 ->
          List.first(response)

        responses ->
          responses
      end

    Boltex.Logger.log_message(:server, message_type, response)
    {message_type, response}
  end
end
