defmodule LevelWeb.InvitationController do
  @moduledoc false

  use LevelWeb, :controller

  alias Level.Spaces
  alias Level.Spaces.User

  def show(conn, %{"id" => id}) do
    invitation = Spaces.get_pending_invitation!(conn.assigns[:space], id)
    changeset = User.signup_changeset(%User{}, %{email: invitation.email})

    conn
    |> assign(:changeset, changeset)
    |> assign(:invitation, invitation)
    |> render("show.html")
  end
end
