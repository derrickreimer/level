defmodule LevelWeb.PageController do
  @moduledoc false

  use LevelWeb, :controller

  plug :put_layout, "page.html"

  def index(conn, _params) do
    conn
    |> assign(:module, "home")
    |> render("index.html")
  end

  def manifesto(conn, _params) do
    render conn, "manifesto.html"
  end
end
