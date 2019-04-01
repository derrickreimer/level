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
              state: :all,
              last_activity: :all,
              privacy: :all,
              recipients: []
            },
            order_by: %{
              field: :posted_at,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: integer() | nil,
          after: integer() | nil,
          filter: %{
            following_state: :is_following | :all,
            inbox_state: :unread | :read | :dismissed | :undismissed | :all,
            state: :open | :closed | :all,
            last_activity: :today | :all,
            privacy: :direct | :all,
            author: String.t(),
            recipients: [String.t()]
          },
          order_by: %{
            field: :posted_at | :last_pinged_at | :last_activity_at,
            direction: :asc | :desc
          }
        }

  @doc """
  Executes a paginated query for posts.
  """
  @spec get(nil | Space.t() | Group.t(), map(), map()) ::
          {:ok, Pagination.Result.t()} | {:error, String.t()}
  def get(parent, args, %{context: %{current_user: user}}) do
    base_query =
      user
      |> Posts.Query.base_query()
      |> build_base_query(parent)
      |> apply_order_fields(args)
      |> apply_following_state(args)
      |> apply_inbox_state(args)
      |> apply_state(args)
      |> apply_last_activity(args)
      |> apply_author(args)
      |> apply_recipients(args)
      |> apply_privacy(args)

    pagination_args =
      args
      |> process_args()
      |> Args.build()

    query = from(p in subquery(base_query))
    Pagination.fetch_result(query, pagination_args)
  end

  defp build_base_query(query, %Space{id: space_id}) do
    Posts.Query.where_in_space(query, space_id)
  end

  defp build_base_query(query, %Group{id: group_id}) do
    Posts.Query.where_in_group(query, group_id)
  end

  defp build_base_query(query, _), do: query

  defp process_args(%{order_by: %{field: :posted_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  defp process_args(args), do: args

  defp apply_order_fields(base_query, %{order_by: %{field: :last_activity_at}}) do
    Posts.Query.select_last_activity_at(base_query)
  end

  defp apply_order_fields(base_query, _), do: base_query

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

  defp apply_last_activity(base_query, %{
         filter: %{last_activity: :today},
         order_by: %{field: :last_activity_at}
       }) do
    Posts.Query.where_last_active_today(base_query, DateTime.utc_now())
  end

  defp apply_last_activity(base_query, _) do
    base_query
  end

  defp apply_author(base_query, %{filter: %{author: handle}}) do
    Posts.Query.where_authored_by(base_query, handle)
  end

  defp apply_author(base_query, _), do: base_query

  defp apply_recipients(base_query, %{filter: %{recipients: []}}), do: base_query

  defp apply_recipients(base_query, %{filter: %{recipients: handles}}) do
    Posts.Query.where_specific_recipients(base_query, handles)
  end

  defp apply_recipients(base_query, _), do: base_query

  defp apply_privacy(base_query, %{filter: %{privacy: :direct}}) do
    Posts.Query.where_is_direct(base_query)
  end

  defp apply_privacy(base_query, _), do: base_query
end
