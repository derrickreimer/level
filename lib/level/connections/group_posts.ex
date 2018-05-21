defmodule Level.Connections.GroupPosts do
  @moduledoc """
  A paginated connection for fetching a group's posts.
  """

  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Repo

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
  Executes a paginated query for a user's group memberships.
  """
  def get(group, args, _info) do
    query = Ecto.assoc(group, :posts)
    args = process_args(args)
    Pagination.fetch_result(Repo, query, Args.build(args))
  end

  def process_args(%{order_by: %{field: :posted_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  def process_args(args), do: args
end
