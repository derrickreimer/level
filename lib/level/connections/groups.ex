defmodule Level.Connections.Groups do
  @moduledoc false

  alias Level.Groups.Group
  alias Level.Pagination
  alias Level.Repo
  import Ecto.Query

  @default_args %{
    first: nil,
    last: nil,
    before: nil,
    after: nil,
    state: "OPEN",
    order_by: %{
      field: :name,
      direction: :asc
    }
  }

  @doc """
  Execute a paginated query for groups belonging to a given space.
  """
  def get(space, args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query = from g in Group, where: g.space_id == ^space.id and g.state == ^args.state

        Pagination.fetch_result(Repo, base_query, args)
    end
  end

  defp validate_args(args) do
    # TODO: return {:error, message} if args are not valid
    {:ok, Map.merge(@default_args, args)}
  end
end
