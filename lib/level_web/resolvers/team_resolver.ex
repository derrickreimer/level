defmodule LevelWeb.TeamResolver do
  @moduledoc """
  GraphQL query resolution for teams.
  """

  def users(team, args, _info) do
    Level.Connections.users(team, args, %{})
  end
end
