defmodule Level.Connections.Groups do
  @moduledoc """
  A paginated connection for fetching groups within the authenticated user's space.
  """

  import Ecto.Query

  alias Level.Groups
  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Spaces.Space

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            state: "OPEN",
            order_by: %{
              field: :name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          state: String.t(),
          order_by: %{field: :name, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for groups belonging to a given space.
  """
  def get(%Space{id: space_id}, %{state: state} = args, %{context: %{current_user: user}}) do
    user
    |> Groups.groups_base_query()
    |> where(space_id: ^space_id, state: ^state)
    |> Pagination.fetch_result(Args.build(args))
  end
end
