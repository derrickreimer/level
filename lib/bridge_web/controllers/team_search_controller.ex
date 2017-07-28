defmodule BridgeWeb.TeamSearchController do
  use BridgeWeb, :controller

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"search" => %{"slug" => slug}}) do
    case Bridge.Repo.get_by(Bridge.Team, %{slug: slug}) do
      nil ->
        conn
        |> put_flash(:error, "We could not find your team")
        |> render("new.html")
      team ->
        redirect(conn, external: team_login_url(conn, team))
    end
  end
end
