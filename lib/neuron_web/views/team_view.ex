defmodule NeuronWeb.TeamView do
  use NeuronWeb, :view

  def team_host(team) do
    "#{team.slug}.#{default_host()}"
  end
end
