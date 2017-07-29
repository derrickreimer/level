defmodule BridgeWeb.SessionController do
  use BridgeWeb, :controller

  plug :fetch_team
  plug :fetch_current_user_by_session
  plug :redirect_if_signed_in

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"username" => username,
                                    "password" => pass}}) do
    case BridgeWeb.Auth.sign_in_with_credentials(conn, conn.assigns.team, username, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: thread_path(conn, :index))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Oops, those credentials are not correct")
        |> render("new.html")
    end
  end

  defp redirect_if_signed_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
      |> redirect(to: thread_path(conn, :index))
      |> halt()
    else
      conn
    end
  end
end
