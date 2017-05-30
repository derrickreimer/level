defmodule Bridge.ThreadController do
  use Bridge.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
