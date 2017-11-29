defmodule LevelWeb.API.SpaceView do
  @moduledoc false

  use LevelWeb, :view

  alias LevelWeb.API.UserView

  def render("create.json", %{space: space, user: user, redirect_url: redirect_url}) do
    %{
      space: space_json(space),
      user: UserView.user_json(user),
      redirect_url: redirect_url
    }
  end

  def render("errors.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end

  def space_json(space) do
    %{
      id: space.id,
      name: space.name,
      slug: space.slug,
      inserted_at: space.inserted_at,
      updated_at: space.updated_at
    }
  end
end
