defmodule Bridge.Web.GenericSessionController do
  use Bridge.Web, :controller

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"slug" => slug}}) do
    case Bridge.Repo.get_by(Bridge.Team, %{slug: slug}) do
      nil ->
        conn
        |> put_flash(:error, "We could not find your team")
        |> render("new.html")
      team ->
        conn
        |> redirect(to: session_path(conn, :new, team))
    end
  end
end
