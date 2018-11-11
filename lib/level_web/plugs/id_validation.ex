defmodule LevelWeb.ValidateIds do
  @moduledoc """
  A plug for validating that ID parameters are valid UUIDs.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Level.Uuid

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    conn.params
    |> Map.to_list()
    |> Enum.filter(fn {key, _} -> key == "id" || String.ends_with?(key, "_id") end)
    |> Enum.all?(fn {_, val} -> Uuid.valid?(val) end)
    |> render_404_unless(conn)
  end

  defp render_404_unless(false, conn), do: render_404(conn)
  defp render_404_unless(true, conn), do: conn

  defp render_404(conn) do
    conn
    |> put_status(404)
    |> put_view(LevelWeb.ErrorView)
    |> render("404.html")
    |> halt()
  end
end
