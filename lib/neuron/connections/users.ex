defmodule Neuron.Connections.Users do
  @moduledoc """
  Functions for querying users.
  """

  alias Neuron.Teams.User
  import Ecto.Query

  @default_args %{
    first: 10,
    before: nil,
    after: nil,
    order_by: %{
      field: :username,
      direction: :asc
    }
  }

  @doc """
  Execute a paginated query for users belonging to a given team.
  """
  def get(team, args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query = from u in User,
          where: u.team_id == ^team.id and u.state == "ACTIVE"

        Neuron.Pagination.fetch_result(Neuron.Repo, base_query, args)
      error ->
        error
    end
  end

  defp validate_args(args) do
    # TODO: return {:error, message} if args are not valid
    {:ok, Map.merge(@default_args, args)}
  end
end
