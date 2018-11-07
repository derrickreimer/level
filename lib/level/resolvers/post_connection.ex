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
              following_state: :all,
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
            following_state: :is_following | :all,
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
      |> apply_following_state(args)
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
    user
    |> Posts.Query.base_query()
    |> Posts.Query.where_in_space(space_id)
  end

  defp build_base_query(user, %Group{id: group_id}) do
    user
    |> Posts.Query.base_query()
    |> Posts.Query.where_in_group(group_id)
  end

  defp process_args(%{order_by: %{field: :posted_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  defp process_args(args), do: args

  defp apply_activity(base_query, %{order_by: %{field: :last_activity_at}}) do
    Posts.Query.select_last_activity_at(base_query)
  end

  defp apply_activity(base_query, _), do: base_query

  defp apply_following_state(base_query, %{filter: %{following_state: :is_following}}) do
    Posts.Query.where_is_following(base_query)
  end

  defp apply_following_state(base_query, _), do: base_query

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :unread}}) do
    Posts.Query.where_unread_in_inbox(base_query)
  end

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :read}}) do
    Posts.Query.where_read_in_inbox(base_query)
  end

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :undismissed}}) do
    Posts.Query.where_undismissed_in_inbox(base_query)
  end

  defp apply_inbox_state(base_query, %{filter: %{inbox_state: :dismissed}}) do
    Posts.Query.where_dismissed_from_inbox(base_query)
  end

  defp apply_inbox_state(base_query, _), do: base_query

  defp apply_state(base_query, %{filter: %{state: :open}}) do
    Posts.Query.where_open(base_query)
  end

  defp apply_state(base_query, %{filter: %{state: :closed}}) do
    Posts.Query.where_closed(base_query)
  end

  defp apply_state(base_query, _), do: base_query
end
