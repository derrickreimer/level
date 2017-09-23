defmodule SprinkleWeb.API.SignupErrorsView do
  use SprinkleWeb, :view

  def render("show.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end
end
