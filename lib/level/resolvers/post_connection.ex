defmodule Level.Resolvers.PostConnection do
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
            has_pings: nil,
            order_by: %{
              field: :posted_at,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          has_pings: boolean() | nil,
          order_by: %{field: :posted_at | :last_pinged_at, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a user's mentioned posts.
  """
  def get(space, args, %{context: %{current_user: user}}) do
    base_query =
      user
      |> build_base_query(space.id)
      |> add_ping_conditions(args)

    pagination_args =
      args
      |> process_args()
      |> Args.build()

    query = from(p in subquery(base_query))
    Pagination.fetch_result(query, pagination_args)
  end

  defp build_base_query(user, space_id) do
    from [p, su, g, gu] in Posts.posts_base_query(user),
      where: p.space_id == ^space_id
  end

  defp process_args(%{order_by: %{field: :posted_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  defp process_args(args), do: args

  defp add_ping_conditions(base_query, %{has_pings: nil, order_by: %{field: :last_pinged_at}}) do
    from [p, su, g, gu] in base_query,
      left_join: m in assoc(p, :user_mentions),
      on: m.mentioned_id == su.id and is_nil(m.dismissed_at),
      group_by: p.id,
      select_merge: %{last_pinged_at: max(m.occurred_at)}
  end

  defp add_ping_conditions(base_query, %{has_pings: true}) do
    from [p, su, g, gu] in base_query,
      join: m in assoc(p, :user_mentions),
      on: m.mentioned_id == su.id and is_nil(m.dismissed_at),
      group_by: p.id,
      select_merge: %{last_pinged_at: max(m.occurred_at)}
  end

  defp add_ping_conditions(base_query, %{has_pings: false}) do
    from [p, su, g, gu] in base_query,
      left_join: m in assoc(p, :user_mentions),
      on: m.mentioned_id == su.id and is_nil(m.dismissed_at),
      where: is_nil(m.id),
      select_merge: %{last_pinged_at: p.inserted_at}
  end

  defp add_ping_conditions(base_query, _), do: base_query
end
