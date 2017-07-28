defmodule BridgeWeb.API.SignupErrorsView do
  use BridgeWeb, :view

  def render("show.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end
end
