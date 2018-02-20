defmodule Level.Connections.Drafts do
  @moduledoc false

  alias Level.Threads.Draft
  import Ecto.Query

  @default_args %{
    first: nil,
    last: nil,
    before: nil,
    after: nil,
    order_by: %{
      field: :updated_at,
      direction: :desc
    }
  }

  @doc """
  Execute a paginated query for users belonging to a given space.
  """
  def get(user, args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query = from d in Draft, where: d.user_id == ^user.id
        Level.Pagination.fetch_result(Level.Repo, base_query, args)

      error ->
        error
    end
  end

  defp validate_args(args) do
    # TODO: return {:error, message} if args are not valid
    {:ok, Map.merge(@default_args, args)}
  end
end
