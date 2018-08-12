defmodule Boltex.Logger do
  require Logger

  @doc """
  Produces a formatted Log
  """
  def log_message(from, {type, data}) do
    msg_type = type |> Atom.to_string() |> String.upcase()
    do_log_message(from, fn -> "#{msg_type} ~ #{inspect(data)}" end)
  end

  def log_message(from, type, data) do
    log_message(from, {type, data})
  end

  def log_message(from, type, data, :hex) do
    if Application.get_env(:boltex, :log_hex, false) do
      msg_type = type |> Atom.to_string() |> String.upcase()

      do_log_message(from, fn ->
        "#{msg_type} ~ #{inspect(data, base: :hex, limit: :infinity)}"
      end)
    end
  end

  defp do_log_message(from, func) when is_function(func) do
    from_txt =
      case from do
        :server -> "S"
        :client -> "C"
      end

    Logger.debug(fn -> "#{from_txt}: #{func.()}" end)
  end
end
