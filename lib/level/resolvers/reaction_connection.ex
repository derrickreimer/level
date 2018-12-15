defmodule Level.Resolvers.ReactionConnection do
  @moduledoc """
  A paginated connection for fetching a post or reply's reactions.
  """

  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Schemas.Post
  alias Level.Schemas.Reply

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :inserted_at,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :inserted_at, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for reactions.
  """
  def get(%Post{} = post, args, _info) do
    query = Ecto.assoc(post, :post_reactions)
    Pagination.fetch_result(query, Args.build(args))
  end

  def get(%Reply{} = reply, args, _info) do
    query = Ecto.assoc(reply, :reply_reactions)
    Pagination.fetch_result(query, Args.build(args))
  end
end
