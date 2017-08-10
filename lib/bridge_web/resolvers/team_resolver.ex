defmodule BridgeWeb.TeamResolver do
  @moduledoc """
  GraphQL query resolution for teams.
  """

  def users(team, args, _info) do
    Bridge.Connections.users(team, args, %{})
  end
end
