defmodule SprinkleWeb.TeamResolver do
  @moduledoc """
  GraphQL query resolution for teams.
  """

  def users(team, args, _info) do
    Sprinkle.Connections.users(team, args, %{})
  end
end
