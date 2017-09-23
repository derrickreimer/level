defmodule SprinkleWeb.TeamView do
  use SprinkleWeb, :view

  def team_host(team) do
    "#{team.slug}.#{default_host()}"
  end
end
