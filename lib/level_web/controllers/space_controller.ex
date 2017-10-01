defmodule LevelWeb.SpaceController do
  use LevelWeb, :controller

  def index(conn, _params) do
    case LevelWeb.Auth.signed_in_spaces(conn) do
      [] ->
        conn
        |> redirect(to: space_search_path(conn, :new))

      spaces ->
        conn
        |> render("index.html", spaces: spaces)
    end
  end

  def new(conn, _params) do
    render conn, "new.html"
  end
end
