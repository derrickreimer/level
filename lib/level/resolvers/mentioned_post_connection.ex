defmodule Level.Resolvers.MentionedPostConnection do
  @moduledoc """
  A paginated connection for fetching a user's mentioned posts.
  """

  import Ecto.Query, warn: false

  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Posts

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :last_occurred_at,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :last_occurred_at, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a user's mentioned posts.
  """
  def get(space, args, %{context: %{current_user: user}}) do
    base_query =
      from [p, su, g, gu, pu] in Posts.posts_base_query(user),
        where: p.space_id == ^space.id,
        join: m in assoc(p, :user_mentions),
        where: m.mentioned_id == su.id and is_nil(m.dismissed_at),
        group_by: [p.id, pu.subscription_state],
        select_merge: %{last_occurred_at: max(m.occurred_at)}

    query = from(p in subquery(base_query))
    Pagination.fetch_result(query, Args.build(args))
  end
end
