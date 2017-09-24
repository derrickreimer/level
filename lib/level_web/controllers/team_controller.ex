defmodule LevelWeb.TeamController do
  use LevelWeb, :controller

  def index(conn, _params) do
    case LevelWeb.Auth.signed_in_teams(conn) do
      [] ->
        conn
        |> redirect(to: team_search_path(conn, :new))

      teams ->
        conn
        |> render("index.html", teams: teams)
    end
  end

  def new(conn, _params) do
    render conn, "new.html"
  end
end
