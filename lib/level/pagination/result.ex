defmodule Level.Pagination.Result do
  @moduledoc false

  defstruct [:total_count, :edges, :page_info]

  @type t :: %__MODULE__{}
end
