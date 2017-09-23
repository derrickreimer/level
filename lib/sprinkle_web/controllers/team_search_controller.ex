defmodule SprinkleWeb.TeamSearchController do
  use SprinkleWeb, :controller

  alias Sprinkle.Teams

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"search" => %{"slug" => slug}}) do
    case Teams.get_team_by_slug(slug) do
      nil ->
        conn
        |> put_flash(:error, "We could not find your team")
        |> render("new.html")
      team ->
        redirect(conn, external: team_login_url(conn, team))
    end
  end
end
