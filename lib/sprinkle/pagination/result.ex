defmodule Sprinkle.Pagination.Result do
  @moduledoc """
  The GraphQL-friendly result of a pagination query.
  """

  defstruct [:total_count, :edges, :page_info]
end
