defmodule LevelWeb.API.SignupErrorsView do
  use LevelWeb, :view

  def render("show.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end
end
