defmodule Bridge.SessionController do
  use Bridge.Web, :controller

  plug :fetch_pod, repo: Bridge.Repo
  plug :fetch_current_user, repo: Bridge.Repo

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"username" => username,
                                    "password" => pass}}) do
    case Bridge.UserAuth.sign_in_with_credentials(conn, conn.assigns.pod, username, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: thread_path(conn, :index, conn.assigns.pod))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render("new.html")
    end
  end
end
