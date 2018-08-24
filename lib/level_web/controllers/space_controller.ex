defmodule LevelWeb.SpaceController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Spaces
  alias LevelWeb.Auth
  alias LevelWeb.ErrorView

  def index(conn, _params) do
    user = conn.assigns[:current_user]

    conn
    |> assign(:api_token, Auth.generate_signed_jwt(user))
    |> assign(:module, "spaces")
    |> assign(:page_title, "My Spaces")
    |> render("index.html")
  end

  def new(conn, _params) do
    user = conn.assigns[:current_user]

    conn
    |> assign(:api_token, Auth.generate_signed_jwt(user))
    |> assign(:module, "new_space")
    |> assign(:page_title, "New Space")
    |> render("new.html")
  end

  def show(conn, %{"path" => ["user" | _]}) do
    user = conn.assigns[:current_user]

    conn
    |> assign(:api_token, Auth.generate_signed_jwt(user))
    |> assign(:module, "main")
    |> assign(:space_id, "")
    |> render("show.html")
  end

  def show(conn, %{"path" => [slug | _]}) do
    user = conn.assigns[:current_user]

    case Spaces.get_space_by_slug(user, slug) do
      {:ok, %{space: space}} ->
        conn
        |> assign(:api_token, Auth.generate_signed_jwt(user))
        |> assign(:module, "main")
        |> assign(:space_id, space.id)
        |> render("show.html")

      _ ->
        conn
        |> put_status(404)
        |> put_view(ErrorView)
        |> render("404.html")
    end
  end
end
