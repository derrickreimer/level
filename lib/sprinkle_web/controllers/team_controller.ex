defmodule SprinkleWeb.TeamController do
  use SprinkleWeb, :controller

  def index(conn, _params) do
    case SprinkleWeb.Auth.signed_in_teams(conn) do
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
