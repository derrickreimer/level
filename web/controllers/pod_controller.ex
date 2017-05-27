defmodule Bridge.PodController do
  use Bridge.Web, :controller

  def new(conn, _params) do
    render conn, "new.html"
  end
end
