defmodule LevelWeb.SpaceSearchController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Spaces

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"search" => %{"slug" => slug}}) do
    case Spaces.get_space_by_slug(slug) do
      nil ->
        conn
        |> put_flash(:error, "We could not find your space")
        |> render("new.html")

      space ->
        redirect(conn, external: space_login_url(conn, space))
    end
  end
end
