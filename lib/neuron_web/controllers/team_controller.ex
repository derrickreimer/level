defmodule NeuronWeb.TeamController do
  use NeuronWeb, :controller

  def index(conn, _params) do
    case NeuronWeb.Auth.signed_in_teams(conn) do
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
