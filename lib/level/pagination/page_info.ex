defmodule Level.Pagination.PageInfo do
  @moduledoc false

  defstruct [:start_cursor, :end_cursor, :has_next_page, :has_previous_page]
end
