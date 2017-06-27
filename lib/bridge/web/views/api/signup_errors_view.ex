defmodule Bridge.Web.API.SignupErrorsView do
  use Bridge.Web, :view

  def render("show.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end
end
