defmodule LevelWeb.PageController do
  use LevelWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
