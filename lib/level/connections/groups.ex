defmodule Level.Connections.Groups do
  @moduledoc false

  alias Level.Groups
  alias Level.Pagination
  alias Level.Repo
  import Ecto.Query
  import Level.Pagination.Validations

  @default_args %{
    first: nil,
    last: nil,
    before: nil,
    after: nil,
    state: "OPEN",
    order_by: %{
      field: :name,
      direction: :asc
    }
  }

  @doc """
  Execute a paginated query for groups belonging to a given space.
  """
  def get(_space, args, %{context: %{current_user: user}}) do
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
    args = Map.merge(@default_args, args)

    with {:ok, args} <- validate_cursor(args),
         {:ok, args} <- validate_limit(args) do
      {:ok, args}
    else
      err -> err
    end
  end
end
