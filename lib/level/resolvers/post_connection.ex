defmodule Level.Resolvers.PostConnection do
  @moduledoc """
  A paginated connection for fetching a user's mentioned posts.
  """

  import Ecto.Query, warn: false

  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Posts
  alias Level.Schemas.Group
  alias Level.Schemas.Space

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            filter: %{
              watching: :all,
              inbox_state: :all,
              state: :all
            },
            order_by: %{
              field: :posted_at,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          filter: %{
            watching: :is_watching | :all,
            inbox_state: :unread | :read | :dismissed | :undismissed | :all,
            state: :open | :closed | :all
          },
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
      |> apply_activity(args)
      |> apply_watching(args)
      |> apply_inbox_state(args)
      |> apply_state(args)

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

  defp apply_activity(base_query, %{order_by: %{field: :last_activity_at}}) do
    from [p, su, g, gu] in base_query,
      left_join: pl in assoc(p, :post_logs),
      group_by: p.id,
      select_merge: %{last_activity_at: max(pl.occurred_at)}
  end

  defp apply_activity(base_query, _), do: base_query

  defp apply_watching(base_query, %{filter: %{watching: :is_watching}}) do
    from [p, su, g, gu] in base_query,
      left_join: pu in assoc(p, :post_users),
      on: pu.space_user_id == su.id,
      where: not is_nil(gu.id) or pu.subscription_state == "SUBSCRIBED",
      group_by: p.id
  end

  defp apply_watching(base_query, _), do: base_query

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :unread}}) do
    from [p, su, g, gu] in base_query,
      join: pu in assoc(p, :post_users),
      on: pu.space_user_id == su.id and pu.inbox_state == "UNREAD"
  end

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :read}}) do
    from [p, su, g, gu] in base_query,
      join: pu in assoc(p, :post_users),
      on: pu.space_user_id == su.id and pu.inbox_state == "READ"
  end

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :undismissed}}) do
    from [p, su, g, gu] in base_query,
      join: pu in assoc(p, :post_users),
      on: pu.space_user_id == su.id and (pu.inbox_state == "UNREAD" or pu.inbox_state == "READ")
  end

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :dismissed}}) do
    from [p, su, g, gu] in base_query,
      join: pu in assoc(p, :post_users),
      on: pu.space_user_id == su.id and pu.inbox_state == "DISMISSED"
  end

  defp apply_inbox_state(base_query, _), do: base_query

  defp apply_state(base_query, %{filter: %{state: :open}}) do
    from [p, su, g, gu] in base_query, where: p.state == "OPEN"
  end

  defp apply_state(base_query, %{filter: %{state: :closed}}) do
    from [p, su, g, gu] in base_query, where: p.state == "CLOSED"
  end

  defp apply_state(base_query, _), do: base_query
end
