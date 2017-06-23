defmodule Bridge.Web.API.TeamView do
  use Bridge.Web, :view

  alias Bridge.Web.API.UserView

  def render("create.json", %{team: team, user: user}) do
    %{
      team: team_json(team),
      user: UserView.user_json(user)
    }
  end

  def render("errors.json", %{changeset: changeset}) do
    %{
      errors: Enum.map(changeset.errors, fn({attr, {msg, props}}) ->
        %{attribute: attr, message: msg, properties: Map.new(props)}
      end)
    }
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
