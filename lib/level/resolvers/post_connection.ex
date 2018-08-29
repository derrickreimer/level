defmodule Level.Resolvers.PostConnection do
  @moduledoc """
  A paginated connection for fetching a user's mentioned posts.
  """

  import Ecto.Query, warn: false

  alias Level.Groups.Group
  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Posts
  alias Level.Spaces.Space

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
          order_by: %{
            field: :posted_at | :last_pinged_at | :last_activity_at,
            direction: :asc | :desc
          }
        }

  @doc """
  Executes a paginated query for posts.
  """
  @spec get(Space.t() | Group.t(), map(), map()) ::
          {:ok, Pagination.Result.t()} | {:error, String.t()}
  def get(parent, args, %{context: %{current_user: user}}) do
    base_query =
      user
      |> build_base_query(parent)
      |> add_ping_conditions(args)
      |> add_activity_conditions(args)

    pagination_args =
      args
      |> process_args()
      |> Args.build()

    query = from(p in subquery(base_query))
    Pagination.fetch_result(query, pagination_args)
  end

  defp build_base_query(user, %Space{id: space_id}) do
    from [p, su, g, gu] in Posts.posts_base_query(user),
      where: p.space_id == ^space_id
  end

  defp build_base_query(user, %Group{id: group_id}) do
    from [p, su, g, gu] in Posts.posts_base_query(user),
      where: g.id == ^group_id
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

  defp add_activity_conditions(base_query, %{order_by: %{field: :last_activity_at}}) do
    from [p, su, g, gu] in base_query,
      left_join: pl in assoc(p, :post_logs),
      group_by: p.id,
      select_merge: %{last_activity_at: max(pl.occurred_at)}
  end

  defp add_activity_conditions(base_query, _), do: base_query
end
