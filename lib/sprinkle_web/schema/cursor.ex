defmodule SprinkleWeb.Schema.Cursor do
  @moduledoc """
  Parsing and serialization methods for GraphQL cursors.
  """

  # defmacro is_datetime(value) do
  #   quote do: false #unquote(value) == %DateTime{}
  # end

  def parse(value) do
    value
    |> Base.url_decode64()
    |> parse_value()
  end

  def serialize(value) do
    value
    |> serialize_value()
    |> Base.url_encode64()
  end

  # defp parse_value("time:" <> timestamp) do
  #   timestamp
  #   |> String.to_integer(timestamp)
  #   |> DateTime.from_unix!()
  # end

  defp parse_value(value) do
    value
  end

  # defp serialize_value(value) when is_datetime(value) do
  #   "timestamp:#{DateTime.to_unix(value)}"
  # end

  defp serialize_value(value) do
    to_string(value)
  end
end
