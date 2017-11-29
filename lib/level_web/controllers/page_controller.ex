defmodule LevelWeb.PageController do
  @moduledoc false

  use LevelWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
