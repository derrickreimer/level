defmodule Level.Connections.GroupMemberships do
  @moduledoc """
  A paginated connection for fetching a user's group memberships.
  """

  import Ecto.Query

  alias Level.Groups.Group
  alias Level.Groups.GroupMembership
  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Repo
  alias Level.Spaces.User

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :name, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a user's group memberships.
  """
  def get(%User{id: user_id, space_id: space_id} = _user, %__MODULE__{} = args, _context) do
    base_query =
      from gm in GroupMembership,
        where: gm.space_id == ^space_id and gm.user_id == ^user_id,
        join: g in Group,
        on: g.id == gm.group_id,
        select: %{gm | name: g.name}

    wrapped_query = from(gm in subquery(base_query))
    Pagination.fetch_result(Repo, wrapped_query, Args.build(args))
  end
end
