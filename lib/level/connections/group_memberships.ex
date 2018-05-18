defmodule Level.Connections.GroupMemberships do
  @moduledoc """
  A paginated connection for fetching a user's group memberships.
  """

  import Ecto.Query
  import Level.Gettext

  alias Level.Groups.Group
  alias Level.Groups.GroupUser
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
  def get(user, args, %{context: %{current_user: authenticated_user}} = _info) do
    if authenticated_user == user do
      case Spaces.get_space(user, args.space_id) do
        {:ok, %{space_user: space_user}} ->
          base_query =
            from gu in GroupUser,
              where: gu.space_user_id == ^space_user.id,
              join: g in Group,
              on: g.id == gu.group_id,
              select: %{gu | name: g.name}

          wrapped_query = from(gu in subquery(base_query))
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
