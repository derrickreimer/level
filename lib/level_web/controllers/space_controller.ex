defmodule LevelWeb.SpaceController do
  @moduledoc false

  use LevelWeb, :controller

  def index(conn, _params) do
    # TODO: fetch spaces the user has access to
    render conn, "index.html"
  end

  def new(conn, _params) do
    render conn, "new.html", module: "signup"
  end
end
