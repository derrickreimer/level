defmodule Level.Resolvers.SearchConnection do
  @moduledoc """
  A paginated connection for fetching search results.
  """

  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Posts
  alias Level.Spaces
  alias Level.Spaces.Space

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            query: nil,
            order_by: %{
              field: :rank,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          query: String.t() | nil,
          order_by: %{
            field: :rank,
            direction: :asc | :desc
          }
        }

  @spec get(Space.t(), map(), map()) :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  def get(%Space{} = space, args, %{context: %{current_user: user}}) do
    case Spaces.get_space_user(user, space) do
      {:ok, space_user} ->
        space_user
        |> Posts.search_query(args.query)
        |> Pagination.fetch_result(Args.build(args))

      err ->
        err
    end
  end
end
