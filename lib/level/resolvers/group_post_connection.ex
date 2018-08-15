defmodule Level.Resolvers.GroupPostConnection do
  @moduledoc """
  A paginated connection for fetching a group's posts.
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
              field: :posted_at,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :posted_at, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a group's posts.
  """
  def get(group, args, %{context: %{current_user: user}}) do
    query =
      from [p, su, g, gu] in Posts.posts_base_query(user),
        where: g.id == ^group.id

    args = process_args(args)
    Pagination.fetch_result(query, Args.build(args))
  end

  def process_args(%{order_by: %{field: :posted_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  def process_args(args), do: args
end
