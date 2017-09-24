defmodule Level.ConnCaseHelpers do
  @moduledoc """
  Test helpers specifically for conn-based tests.
  """

  import Level.TestHelpers
  import Plug.Conn

  def sign_in(conn, team, user) do
    conn
    |> LevelWeb.Auth.sign_in(team, user)
    |> send_resp(:ok, "")
    |> Phoenix.ConnTest.recycle
  end

  def authenticate_with_jwt(conn, team, user) do
    token = LevelWeb.Auth.generate_signed_jwt(user)

    conn
    |> put_team_host(team)
    |> put_req_header("authorization", "Bearer #{token}")
  end

  def render_json(view, template, assigns) do
    assigns = Map.new(assigns)

    template
    |> view.render(assigns)
    |> format_json()
  end

  defp format_json(data) do
    data
    |> Poison.encode!
    |> Poison.decode!
  end
end
