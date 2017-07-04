defmodule Bridge.ConnCaseHelpers do
  def sign_in(conn, team, user) do
    conn
    |> Bridge.Web.UserAuth.sign_in(team, user)
    |> Plug.Conn.send_resp(:ok, "")
    |> Phoenix.ConnTest.recycle
  end

  def render_json(view, template, assigns) do
    assigns = Map.new(assigns)

    template
    |> view.render(assigns)
    |> format_json()
  end

  defp format_json(data) do
    data |> Poison.encode! |> Poison.decode!
  end
end
