defmodule Level.Resolvers.ReplyConnection do
  @moduledoc """
  A paginated connection for fetching a post's replies.
  """

  alias Level.Pagination
  alias Level.Pagination.Args

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :posted_at,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :posted_at, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for a post's replies.
  """
  def get(post, args, _info) do
    query = Ecto.assoc(post, :replies)
    args = process_args(args)
    Pagination.fetch_result(query, Args.build(args))
  end

  def process_args(%{order_by: %{field: :posted_at} = order_by} = args) do
    %{args | order_by: %{order_by | field: :inserted_at}}
  end

  def process_args(args), do: args
end
