defmodule LevelWeb.UserController do
  @moduledoc false

  use LevelWeb, :controller

  import Level.FeatureFlags

  alias Level.Schemas.User
  alias Level.Users

  plug :check_feature_flag

  def new(conn, _params) do
    case conn.assigns[:current_user] do
      %User{} ->
        conn
        |> redirect(to: main_path(conn, :index, ["spaces"]))

      _ ->
        conn
        |> assign(:changeset, Users.create_user_changeset(%User{}))
        |> assign(:page_title, "Sign up for Level")
        |> render("new.html")
    end
  end

  def create(conn, %{"user" => user_params}) do
    case Users.create_user(user_params) do
      {:ok, user} ->
        conn
        |> LevelWeb.Auth.sign_in(user)
        |> redirect(to: main_path(conn, :index, ["spaces", "new"]))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  defp check_feature_flag(conn, _opts) do
    config = Application.get_env(:level, :signups)

    if signups_enabled?(config, conn.params["key"]) do
      conn
    else
      conn
      |> redirect(to: page_path(conn, :index))
      |> halt()
    end
  end
end
