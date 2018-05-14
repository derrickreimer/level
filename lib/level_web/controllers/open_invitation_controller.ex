defmodule LevelWeb.OpenInvitationController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Repo
  alias Level.Spaces
  alias LevelWeb.ErrorView

  plug :fetch_invitation
  plug :fetch_current_user_by_session

  def show(conn, %{"id" => _invitation_token}) do
    render conn, "show.html"
  end

  def accept(conn, _params) do
  end

  defp fetch_invitation(conn, _) do
    case Spaces.get_open_invitation_by_token(conn.params["id"]) do
      {:ok, invitation} ->
        invitation =
          invitation
          |> Repo.preload(:space)

        assign(conn, :invitation, invitation)
        assign(conn, :space, invitation.space)

      {:error, _} ->
        conn
        |> put_status(404)
        |> put_view(ErrorView)
        |> render("404.html")
        |> halt()
    end
  end
end
