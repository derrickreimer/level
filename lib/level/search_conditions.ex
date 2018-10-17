defmodule Level.SearchConditions do
  @moduledoc """
  Macros for building text-search queries in Postgres.
  """

  defmacro ts_rank(vector, query) do
    quote do
      fragment("ts_rank(?, ?)", unquote(vector), unquote(query))
    end
  end

  defmacro plainto_tsquery(config, querytext) do
    quote do
      fragment("plainto_tsquery(?, ?)", unquote(config), unquote(querytext))
    end
  end

  defmacro ts_headline(config, document, query) do
    quote do
      fragment("ts_headline(?, ?, ?)", unquote(config), unquote(document), unquote(query))
    end
  end

  defmacro ts_match(vector, query) do
    quote do
      fragment("? @@ ?", unquote(vector), unquote(query))
    end
  end
end
