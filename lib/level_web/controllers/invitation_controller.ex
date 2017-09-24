defmodule LevelWeb.InvitationController do
  use LevelWeb, :controller

  alias Level.Teams
  alias Level.Teams.User

  plug :fetch_team

  def show(conn, %{"id" => id}) do
    invitation = Teams.get_pending_invitation!(conn.assigns[:team], id)
    changeset = User.signup_changeset(%User{}, %{email: invitation.email})

    conn
    |> assign(:changeset, changeset)
    |> assign(:invitation, invitation)
    |> render("show.html")
  end
end
