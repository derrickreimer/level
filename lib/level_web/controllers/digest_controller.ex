defmodule LevelWeb.DigestController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Digests

  plug LevelWeb.ValidateIds

  def show(conn, %{"space_id" => space_id, "digest_id" => digest_id}) do
    case Digests.get_digest(space_id, digest_id) do
      {:ok, digest} ->
        conn
        |> assign(:preheader, "")
        |> assign(:subject, digest.subject)
        |> assign(:digest, digest)
        |> put_layout({LevelWeb.LayoutView, "branded_email.html"})
        |> render("show.html")

      _ ->
        render_404(conn)
    end
  end

  defp render_404(conn) do
    conn
    |> put_status(404)
    |> put_view(LevelWeb.ErrorView)
    |> render("404.html")
    |> halt()
  end
end
