defmodule Level.Resolvers.GroupConnection do
  @moduledoc """
  A paginated connection for fetching groups within the authenticated user's space.
  """

  import Ecto.Query

  alias Level.Groups
  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Schemas.Space

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            state: :open,
            order_by: %{
              field: :name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          state: :open | :closed | :all,
          order_by: %{field: :name, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for groups belonging to a given space.
  """
  def get(%Space{id: space_id}, args, %{context: %{current_user: user}}) do
    user
    |> Groups.groups_base_query()
    |> where(space_id: ^space_id)
    |> apply_state_filter(args)
    |> Pagination.fetch_result(Args.build(args))
  end

  defp apply_state_filter(query, %{state: :open}) do
    where(query, state: "OPEN")
  end

  defp apply_state_filter(query, %{state: :closed}) do
    where(query, state: "CLOSED")
  end

  defp apply_state_filter(query, _), do: query
end
