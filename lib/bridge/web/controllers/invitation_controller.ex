defmodule Bridge.Web.InvitationController do
  use Bridge.Web, :controller

  alias Bridge.Invitation
  alias Bridge.User

  plug :fetch_team

  def show(conn, %{"id" => id}) do
    # TODO: ensure it's not expired
    invitation =
      Invitation
      |> Repo.get_by!(team_id: conn.assigns[:team].id, state: "PENDING", token: id)
      |> Repo.preload([:team, :invitor])

    conn
    |> assign(:changeset, User.signup_changeset(%Bridge.User{}, %{email: invitation.email}))
    |> assign(:invitation, invitation)
    |> render("show.html")
  end
end
