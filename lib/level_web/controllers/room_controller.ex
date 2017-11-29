defmodule LevelWeb.RoomController do
  @moduledoc false

  use LevelWeb, :controller

  def show(conn, _params) do
    user = conn.assigns[:current_user]
    api_token = LevelWeb.Auth.generate_signed_jwt(user)
    render conn, "show.html", api_token: api_token
  end
end
