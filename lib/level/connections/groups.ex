defmodule Level.Connections.Groups do
  @moduledoc """
  A paginated connection for fetching groups within the authenticated user's space.
  """

  import Ecto.Query
  import Level.Pagination.Validations

  alias Level.Groups
  alias Level.Pagination
  alias Level.Repo

  defstruct first: nil,
            last: nil,
            before: nil,
            after: nil,
            state: "OPEN",
            order_by: %{
              field: :name,
              direction: :asc
            }

  @type t :: %__MODULE__{
          first: integer() | nil,
          last: integer() | nil,
          before: String.t() | nil,
          after: String.t() | nil,
          state: String.t(),
          order_by: %{field: :name, direction: :asc | :desc}
        }

  @doc """
  Executes a paginated query for groups belonging to a given space.
  """
  def get(_space, %__MODULE__{} = args, %{context: %{current_user: user}} = _context) do
    case validate_args(args) do
      {:ok, %{state: state} = args} ->
        base_query =
          user
          |> Groups.list_groups_query()
          |> where(state: ^state)

        Pagination.fetch_result(Repo, base_query, args)

      err ->
        err
    end
  end

  defp validate_args(args) do
    with {:ok, args} <- validate_cursor(args),
         {:ok, args} <- validate_limit(args) do
      {:ok, args}
    else
      err -> err
    end
  end
end
