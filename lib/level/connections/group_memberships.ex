defmodule Level.Connections.GroupMemberships do
  @moduledoc """
  A paginated connection for fetching a user's group memberships.
  """

  import Ecto.Query
  import Level.Gettext

  alias Level.Groups.Group
  alias Level.Groups.GroupMembership
  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Repo
  alias Level.Spaces

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            space_id: nil,
            order_by: %{
              field: :name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          space_id: String.t(),
          order_by: %{field: :name, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a user's group memberships.
  """
  def get(user, args, %{context: %{current_user: authenticated_user}} = _context) do
    if authenticated_user == user do
      case Spaces.get_space(user, args.space_id) do
        {:ok, %{member: member}} ->
          base_query =
            from gm in GroupMembership,
              where: gm.space_member_id == ^member.id,
              join: g in Group,
              on: g.id == gm.group_id,
              select: %{gm | name: g.name}

          wrapped_query = from(gm in subquery(base_query))
          Pagination.fetch_result(Repo, wrapped_query, Args.build(args))

        error ->
          error
      end
    else
      {:error,
       dgettext("errors", "Group memberships are only readable for the authenticated user")}
    end
  end
end
