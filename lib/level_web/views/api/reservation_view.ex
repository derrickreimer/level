defmodule LevelWeb.API.ReservationView do
  @moduledoc false

  use LevelWeb, :view

  def render("errors.json", %{changeset: changeset}) do
    json_validation_errors(changeset)
  end
end
