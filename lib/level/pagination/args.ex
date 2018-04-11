defmodule Level.Pagination.Args do
  @moduledoc """
  Arguments for pagination.
  """

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{field: :id, direction: :asc}

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: atom(), direction: :asc | :desc}
        }

  @typedoc "Input arguments that can be cast to pagination args."
  @type input_args :: %{
          required(:first) => integer() | nil,
          required(:last) => integer() | nil,
          required(:before) => String.t() | nil,
          required(:after) => String.t() | nil,
          required(:order_by) => %{field: atom(), direction: :asc | :desc},
          optional(atom()) => any()
        }

  @spec build(input_args()) :: t()
  def build(args) do
    struct(__MODULE__, Map.take(args, [:first, :last, :before, :after, :order_by]))
  end
end
