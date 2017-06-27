defmodule Bridge.Web.API.SignupErrorsController do
  use Bridge.Web, :controller

  def index(conn, params) do
    changeset = Bridge.Signup.form_changeset(%{}, params)
    render conn, "show.json", %{changeset: changeset}
  end
end
