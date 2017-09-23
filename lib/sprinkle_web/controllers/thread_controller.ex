defmodule SprinkleWeb.ThreadController do
  use SprinkleWeb, :controller

  def index(conn, _params) do
    user = conn.assigns[:current_user]
    api_token = SprinkleWeb.Auth.generate_signed_jwt(user)
    render conn, "index.html", api_token: api_token
  end
end
