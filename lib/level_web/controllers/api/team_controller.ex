defmodule LevelWeb.API.SpaceController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Spaces

  def create(conn, %{"signup" => signup_params}) do
    changeset = Spaces.registration_changeset(%{}, signup_params)

    if changeset.valid? do
      case Spaces.register(changeset) do
        {:ok, %{space: space, user: user}} ->
          conn
          |> LevelWeb.Auth.sign_in(space, user)
          |> put_status(:created)
          |> render("create.json", %{
            space: space,
            user: user,
            redirect_url: threads_url(conn, space)
          })

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
