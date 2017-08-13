defmodule BridgeWeb.API.SignupErrorsController do
  use BridgeWeb, :controller

  alias Bridge.Teams

  def index(conn, %{"signup" => params}) do
    changeset = Teams.registration_changeset(%{}, params)
    render conn, "show.json", %{changeset: changeset}
  end
end
