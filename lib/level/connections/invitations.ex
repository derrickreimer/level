defmodule Level.Connections.Invitations do
  @moduledoc false

  alias Level.Spaces.Invitation
  alias Level.Pagination
  alias Level.Repo
  import Ecto.Query

  @default_args %{
    first: nil,
    last: nil,
    before: nil,
    after: nil,
    order_by: %{
      field: :email,
      direction: :asc
    }
  }

  @doc """
  Execute a paginated query for invitations belonging to a given space.
  """
  def get(space, args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query = from i in Invitation, where: i.space_id == ^space.id and i.state == "PENDING"

        Pagination.fetch_result(Repo, base_query, args)
    end
  end

  defp validate_args(args) do
    # TODO: return {:error, message} if args are not valid
    {:ok, Map.merge(@default_args, args)}
  end
end
