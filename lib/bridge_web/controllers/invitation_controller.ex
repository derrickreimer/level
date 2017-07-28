defmodule BridgeWeb.InvitationController do
  use BridgeWeb, :controller

  alias Bridge.Invitation
  alias Bridge.User

  plug :fetch_team

  def show(conn, %{"id" => id}) do
    invitation = Invitation.fetch_pending!(conn.assigns[:team], id)
    changeset = User.signup_changeset(%Bridge.User{}, %{email: invitation.email})

    conn
    |> assign(:changeset, changeset)
    |> assign(:invitation, invitation)
    |> render("show.html")
  end
end
