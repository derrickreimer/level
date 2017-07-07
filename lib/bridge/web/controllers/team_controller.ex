defmodule Bridge.Web.TeamController do
  use Bridge.Web, :controller
  alias Bridge.Signup

  def new(conn, _params) do
    changeset = Signup.form_changeset(%{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"signup" => signup_params}) do
    changeset = Signup.form_changeset(%{}, signup_params)

    if changeset.valid? do
      case Repo.transaction(Signup.transaction(changeset)) do
        {:ok, %{team: team, user: user}} ->
          conn
          |> Bridge.Web.Auth.sign_in(team, user)
          |> redirect(to: thread_path(conn, :index))
        {:error, _, _, _} ->
          conn
          |> put_flash(:error, gettext("Uh oh, something went wrong. Please try again."))
          |> render("new.html", changeset: changeset)
      end
    else
      changeset = %{changeset | action: :insert}
      render conn, "new.html", changeset: changeset
    end
  end
end
