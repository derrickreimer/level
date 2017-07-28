defmodule BridgeWeb.TeamView do
  use BridgeWeb, :view

  def team_host(team) do
    "#{team.slug}.#{default_host()}"
  end
end
