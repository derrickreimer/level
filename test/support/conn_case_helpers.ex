defmodule Level.ConnCaseHelpers do
  @moduledoc """
  Test helpers specifically for conn-based tests.
  """

  import Plug.Conn

  def sign_in(conn, user) do
    conn
    |> LevelWeb.Auth.sign_in(user)
    |> send_resp(:ok, "")
    |> Phoenix.ConnTest.recycle()
  end

  def authenticate_with_jwt(conn, user) do
    token = LevelWeb.Auth.generate_signed_jwt(user)
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

  def render_json(view, template, assigns) do
    assigns = Map.new(assigns)

    template
    |> view.render(assigns)
    |> format_json()
  end

  defp format_json(data) do
    data
    |> Poison.encode!()
    |> Poison.decode!()
  end
end
