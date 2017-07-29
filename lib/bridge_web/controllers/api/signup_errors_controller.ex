defmodule BridgeWeb.API.SignupErrorsController do
  use BridgeWeb, :controller

  def index(conn, %{"signup" => params}) do
    changeset = Bridge.Signup.form_changeset(%{}, params)
    render conn, "show.json", %{changeset: changeset}
  end
end
