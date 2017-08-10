defmodule Bridge.Connections.Users do
  @moduledoc """
  Helpers for querying team users.
  """

  alias Bridge.User
  import Ecto.Query

  @default_args %{
    first: 10,
    before: nil,
    after: nil,
    order_by: %{
      field: :username,
      direction: :asc
    }
  }

  @doc """
  Execute a query for users.

  Acceptable arguments include:

  - `first`    - the number of rows to return.
  - `after`    - the cursor.
  - `order_by` - the field and direction by which to order the results.
  """
  def get(team, args, _context) do
    base_query = from u in User,
      where: u.team_id == ^team.id and u.state == "ACTIVE"

    args = parse_args(args)
    Bridge.Pagination.fetch_result(Bridge.Repo, base_query, args)
  end

  defp parse_args(args) do
    Map.merge(@default_args, args)
  end
end
