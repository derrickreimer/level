defmodule LevelWeb.PageController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Schemas.Space
  alias Level.Spaces
  alias Level.Users

  plug :put_layout, "page.html"

  def index(%Plug.Conn{assigns: %{current_user: user}} = conn, _params) when not is_nil(user) do
    case Spaces.get_first_member_space(user) do
      %Space{} = space ->
        conn
        |> redirect(to: main_path(conn, :index, [space.slug]))

      nil ->
        conn
        |> redirect(to: main_path(conn, :index, ["spaces", "new"]))
    end
  end

  def index(conn, _params) do
    reservation_count =
      Users.reservation_count()
      |> Number.Delimit.number_to_delimited(precision: 0)

    conn
    |> assign(:module, "home")
    |> assign(:reservation_count, reservation_count)
    |> render("index.html")
  end

  def manifesto(conn, _params) do
    render conn, "manifesto.html"
  end

  def post_preorder(conn, _params) do
    render conn, "post_preorder.html"
  end

  def privacy(conn, _params) do
    render conn, "privacy.html"
  end
end
