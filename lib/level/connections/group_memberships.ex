defmodule Level.Connections.GroupMemberships do
  @moduledoc false

  alias Level.Groups.Group
  alias Level.Groups.GroupMembership
  alias Level.Spaces.User
  alias Level.Pagination
  alias Level.Repo
  import Ecto.Query
  import Level.Pagination.Validations

  @default_args %{
    first: nil,
    last: nil,
    before: nil,
    after: nil,
    order_by: %{
      field: :name,
      direction: :asc
    }
  }

  def get(%User{space_id: space_id} = user, args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query =
          from gm in GroupMembership,
            where: gm.space_id == ^space_id,
            join: g in Group,
            on: g.id == gm.group_id,
            select: %{gm | name: g.name}

        wrapped_query = from(gm in subquery(base_query))
        Pagination.fetch_result(Repo, wrapped_query, args)

      err ->
        err
    end
  end

  def order do
  end

  defp validate_args(args) do
    args = Map.merge(@default_args, args)

    with {:ok, args} <- validate_cursor(args),
         {:ok, args} <- validate_limit(args) do
      {:ok, args}
    else
      err -> err
    end
  end
end
