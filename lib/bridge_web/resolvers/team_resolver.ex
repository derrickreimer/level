defmodule BridgeWeb.TeamResolver do
  @moduledoc """
  GraphQL query resolution for teams.
  """

  def users(team, args, _info) do
    Bridge.TeamUserQuery.run(team, args, %{})
  end
end
