defmodule SprinkleWeb.API.SignupErrorsController do
  use SprinkleWeb, :controller

  alias Sprinkle.Teams

  def index(conn, %{"signup" => params}) do
    changeset = Teams.registration_changeset(%{}, params)
    render conn, "show.json", %{changeset: changeset}
  end
end
