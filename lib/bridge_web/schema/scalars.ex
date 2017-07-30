defmodule BridgeWeb.Schema.Scalars do
  @moduledoc """
  GraphQL scalar type definitions.
  """

  use Absinthe.Schema.Notation

  @desc """
  The `Time` scalar type represents time values provided in the ISOz
  datetime format (that is, the ISO 8601 format without the timezone offset, e.g.,
  "2015-06-24T04:50:34Z").
  """
  scalar :time, description: "ISOz time" do
    parse &Timex.parse(&1.value, "{ISO:Extended:Z}")
    serialize &Timex.format!(&1, "{ISO:Extended:Z}")
  end

  scalar :cursor, description: "A cursor for pagination" do
    parse &Base.url_decode64(&1.value)
    serialize &Base.url_encode64(&1)
  end
end
