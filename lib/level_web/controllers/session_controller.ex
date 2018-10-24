defmodule LevelWeb.SessionController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.FeatureFlags

  plug :fetch_current_user_by_session
  plug :redirect_if_signed_in
  plug :put_feature_flags

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"email" => email, "password" => pass}}) do
    case LevelWeb.Auth.sign_in_with_credentials(conn, email, pass) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: main_path(conn, :index, ["spaces"]))

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Oops, those credentials are not correct")
        |> render("new.html")
    end
  end

  defp redirect_if_signed_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
      |> redirect(to: main_path(conn, :index, ["spaces"]))
      |> halt()
    else
      conn
    end
  end

  defp put_feature_flags(conn, _opts) do
    conn
    |> assign(:signups_enabled, FeatureFlags.signups_enabled?(env()))
  end

  defp env do
    Application.get_env(:level, :env)
  end
end
