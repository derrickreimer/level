defmodule Level.Connections.GroupMemberships do
  @moduledoc """
  A paginated connection for fetching a group's memberships.
  """

  import Ecto.Query

  alias Level.Groups.GroupUser
  alias Level.Pagination
  alias Level.Pagination.Args

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :last_name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :last_name, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a group's memberships.
  """
  def get(group, args, %{context: %{current_user: _authenticated_user}} = _info) do
    base_query =
      from gu in GroupUser,
        where: gu.group_id == ^group.id,
        join: su in assoc(gu, :space_user),
        select: %{gu | last_name: su.last_name}

    wrapped_query = from(gu in subquery(base_query))
    Pagination.fetch_result(wrapped_query, Args.build(args))
  end
end
