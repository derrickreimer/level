defmodule Bridge.SessionController do
  use Bridge.Web, :controller

  plug :fetch_team, repo: Bridge.Repo
  plug :fetch_current_user, repo: Bridge.Repo
  plug :redirect_if_signed_in

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"username" => username,
                                    "password" => pass}}) do
    case Bridge.UserAuth.sign_in_with_credentials(conn, conn.assigns.team, username, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: thread_path(conn, :index, conn.assigns.team))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Oops, those credentials are not correct")
        |> render("new.html")
    end
  end

  defp redirect_if_signed_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
      |> redirect(to: thread_path(conn, :index, conn.assigns.team))
      |> halt()
    else
      conn
    end
  end
end
