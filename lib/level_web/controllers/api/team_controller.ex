defmodule LevelWeb.API.TeamController do
  use LevelWeb, :controller

  alias Level.Teams

  def create(conn, %{"signup" => signup_params}) do
    changeset = Teams.registration_changeset(%{}, signup_params)

    if changeset.valid? do
      case Teams.register(changeset) do
        {:ok, %{team: team, user: user}} ->
          conn
          |> LevelWeb.Auth.sign_in(team, user)
          |> put_status(:created)
          |> render("create.json", %{team: team, user: user, redirect_url: threads_url(conn, team)})
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
