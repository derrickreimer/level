defmodule LevelWeb.PageController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Users

  plug :put_layout, "page.html"

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
end
