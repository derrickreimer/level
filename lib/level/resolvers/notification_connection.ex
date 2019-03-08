defmodule Level.Resolvers.NotificationConnection do
  @moduledoc """
  A paginated connection for fetching a post's replies.
  """

  import Ecto.Query

  alias Level.Notifications
  alias Level.Pagination
  alias Level.Pagination.Args

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :occurred_at,
              direction: :desc
            },
            filters: %{
              state: :all
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: DateTime.t() | nil,
          after: DateTime.t() | nil,
          order_by: %{field: :occurred_at, direction: :asc | :desc},
          filters: %{state: :all | :undismissed | :dismissed}
        }

  @doc """
  Executes a paginated query for a post's replies.
  """
  def get(args, %{context: %{current_user: user}}) do
    user
    |> Notifications.query()
    |> apply_state_filter(args)
    |> Pagination.fetch_result(Args.build(process_args(args)))
  end

  def process_args(%{order_by: %{field: :occurred_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  def process_args(args), do: args

  defp apply_state_filter(query, %{filters: %{state: :undismissed}}) do
    where(query, [n], n.state == "UNDISMISSED")
  end

  defp apply_state_filter(query, %{filters: %{state: :dismissed}}) do
    where(query, [n], n.state == "DISMISSED")
  end

  defp apply_state_filter(query, _) do
    query
  end
end
