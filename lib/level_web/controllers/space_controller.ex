defmodule LevelWeb.SpaceController do
  @moduledoc false

  use LevelWeb, :controller

  alias LevelWeb.Auth

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
end
