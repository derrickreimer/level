defmodule Level.Connections.SpaceUsers do
  @moduledoc """
  A paginated connection for fetching spaces a user belongs to.
  """

  import Ecto.Query
  import Level.Gettext

  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Repo
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

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
  Executes a paginated query for groups belonging to a given space.
  """
  def get(user, args, %{context: %{current_user: authenticated_user}} = _info) do
    if authenticated_user == user do
      base_query =
        from su in SpaceUser,
          where: su.user_id == ^user.id,
          join: s in Space,
          on: s.id == su.space_id,
          select: %{su | name: s.name}

      wrapped_query = from(su in subquery(base_query))
      Pagination.fetch_result(Repo, wrapped_query, Args.build(args))
    else
      {:error, dgettext("errors", "Space users are only readable for the authenticated user")}
    end
  end
end
