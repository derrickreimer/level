defmodule LevelWeb.UserController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Users
  alias Level.Users.User

  def new(conn, _params) do
    case conn.assigns[:current_user] do
      %User{} ->
        conn
        |> redirect(to: space_path(conn, :index))

      _ ->
        conn
        |> assign(:changeset, Users.create_user_changeset(%User{}))
        |> render("new.html")
    end
  end

  def create(conn, %{"user" => user_params}) do
    case Users.create_user(user_params) do
      {:ok, user} ->
        conn
        |> LevelWeb.Auth.sign_in(user)
        |> redirect(to: space_path(conn, :new))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end
end
