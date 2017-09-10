defmodule NeuronWeb.API.SignupErrorsView do
  use NeuronWeb, :view

  def render("show.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end
end
