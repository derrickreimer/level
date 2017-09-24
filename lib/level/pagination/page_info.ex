defmodule Level.Pagination.PageInfo do
  @moduledoc """
  The GraphQL-friendly struct representing pagination information.
  """

  defstruct [:start_cursor, :end_cursor, :has_next_page, :has_previous_page]
end
