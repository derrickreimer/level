defmodule LevelWeb.CockpitController do
  @moduledoc false

  use LevelWeb, :controller

  alias LevelWeb.Auth

  def index(conn, _params) do
    user = conn.assigns[:current_user]

    conn
    |> assign(:api_token, Auth.generate_signed_jwt(user))
    |> assign(:module, "main")
    |> render("index.html")
  end
end
