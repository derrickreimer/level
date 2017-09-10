defmodule NeuronWeb.ThreadController do
  use NeuronWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
