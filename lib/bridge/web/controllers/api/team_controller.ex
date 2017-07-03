defmodule Bridge.Web.API.TeamController do
  use Bridge.Web, :controller
  alias Bridge.Signup

  def create(conn, %{"signup" => signup_params}) do
    changeset = Signup.form_changeset(%{}, signup_params)

    if changeset.valid? do
      case Repo.transaction(Signup.transaction(changeset)) do
        {:ok, %{team: team, user: user}} ->
          conn
          |> Bridge.Web.UserAuth.sign_in(team, user)
          |> put_status(:created)
          |> render("create.json", %{team: team, user: user})
        {:error, _, _, _} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render("errors.json", changeset: changeset)
      end
    else
      conn
      |> put_status(:unprocessable_entity)
      |> render("errors.json", changeset: changeset)
    end
  end
end
