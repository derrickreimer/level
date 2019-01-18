defmodule Level.StringHelpers do
  @moduledoc """
  Various string helper functions.
  """

  def truncate(text) do
    if String.length(text) > 30 do
      String.slice(text, 0..30) <> "..."
    else
      text
    end
  end
end
