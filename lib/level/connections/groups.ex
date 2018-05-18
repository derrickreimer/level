defmodule Level.Connections.Groups do
  @moduledoc """
  A paginated connection for fetching groups within the authenticated user's space.
  """

  import Ecto.Query

  alias Level.Groups
  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Repo
  alias Level.Spaces

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
  def get(space, args, %{context: %{current_user: user}} = _info) do
    case Spaces.get_space(user, space.id) do
      {:ok, %{space_user: space_user}} ->
        base_query =
          space_user
          |> Groups.list_groups_query()
          |> where(state: ^args.state)

        Pagination.fetch_result(Repo, base_query, Args.build(args))

      error ->
        error
    end
  end
end
