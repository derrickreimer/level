defmodule Bridge.Web.TeamView do
  use Bridge.Web, :view

  def team_host(team) do
    "#{team.slug}.#{default_host()}"
  end
end
