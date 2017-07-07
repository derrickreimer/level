defmodule Bridge.Web.API.TeamView do
  use Bridge.Web, :view

  alias Bridge.Web.API.UserView

  def render("create.json", %{team: team, user: user, redirect_url: redirect_url}) do
    %{
      team: team_json(team),
      user: UserView.user_json(user),
      redirect_url: redirect_url
    }
  end

  def render("errors.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end

  def team_json(team) do
    %{
      id: team.id,
      name: team.name,
      slug: team.slug,
      inserted_at: team.inserted_at,
      updated_at: team.updated_at
    }
  end
end
