defmodule BridgeWeb.InvitationController do
  use BridgeWeb, :controller

  alias Bridge.Teams
  alias Bridge.Teams.User

  plug :fetch_team

  def show(conn, %{"id" => id}) do
    invitation = Teams.get_pending_invitation!(conn.assigns[:team], id)
    changeset = User.signup_changeset(%Bridge.Teams.User{}, %{email: invitation.email})

    conn
    |> assign(:changeset, changeset)
    |> assign(:invitation, invitation)
    |> render("show.html")
  end
end
