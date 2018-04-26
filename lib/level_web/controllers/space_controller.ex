defmodule LevelWeb.SpaceController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Spaces
  alias LevelWeb.Auth
  alias LevelWeb.ErrorView

  def index(conn, _params) do
    # TODO: fetch spaces the user has access to
    render conn, "index.html"
  end

  def new(conn, _params) do
    user = conn.assigns[:current_user]

    conn
    |> assign(:api_token, Auth.generate_signed_jwt(user))
    |> assign(:module, "new_space")
    |> render("new.html")
  end

  def show(conn, %{"slug" => slug}) do
    user = conn.assigns[:current_user]

    case Spaces.get_space_by_slug(user, slug) do
      {:ok, %{space: space}} ->
        conn
        |> assign(:api_token, Auth.generate_signed_jwt(user))
        |> assign(:module, "space")
        |> assign(:space_id, space.id)
        |> render("show.html")

      _ ->
        conn
        |> put_status(404)
        |> render(ErrorView, "404.html")
    end
  end
end
