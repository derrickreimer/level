defmodule LevelWeb.TeamView do
  use LevelWeb, :view

  def team_host(team) do
    "#{team.slug}.#{default_host()}"
  end
end
