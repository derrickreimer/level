defmodule LevelWeb.API.SignupErrorsController do
  use LevelWeb, :controller

  alias Level.Teams

  def index(conn, %{"signup" => params}) do
    changeset = Teams.registration_changeset(%{}, params)
    render conn, "show.json", %{changeset: changeset}
  end
end
