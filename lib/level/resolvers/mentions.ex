defmodule Level.Resolvers.Mentions do
  @moduledoc """
  A paginated connection for fetching groups within the authenticated user's space.
  """

  alias Level.Mentions
  alias Level.Spaces
  alias Level.Pagination
  alias Level.Pagination.Args
  alias Level.Spaces.Space

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            order_by: %{
              field: :last_occurred_at,
              direction: :desc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          order_by: %{field: :last_occurred_at, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for mentions of the current user.
  """
  def get(%Space{} = space, args, %{context: %{current_user: user}}) do
    case Spaces.get_space_user(user, space) do
      {:ok, space_user} ->
        space_user
        |> Mentions.base_query()
        |> Pagination.fetch_result(Args.build(args))

      err ->
        err
    end
  end
end
