defmodule LevelWeb.DigestController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Digests
  alias Level.Spaces

  def show(conn, %{"space_id" => space_id, "digest_id" => digest_id}) do
    with {:ok, %{space_user: space_user}} <-
           Spaces.get_space(conn.assigns[:current_user], space_id),
         {:ok, digest} <- Digests.get_digest(space_user, digest_id) do
      conn
      |> assign(:preheader, "")
      |> assign(:subject, digest.subject)
      |> assign(:digest, digest)
      |> put_layout({LevelWeb.LayoutView, "branded_email.html"})
      |> render("show.html")
    else
      _ ->
        conn
        |> put_status(404)
        |> put_view(ErrorView)
        |> render("404.html")
        |> halt()
    end
  end
end
