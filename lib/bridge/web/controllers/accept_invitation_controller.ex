defmodule Bridge.Web.AcceptInvitationController do
  use Bridge.Web, :controller

  alias Bridge.Invitation

  plug :fetch_team

  def create(conn, %{"id" => id, "user" => user_params}) do
    invitation = Invitation.fetch_pending!(conn.assigns[:team], id)

    case Invitation.accept(invitation, user_params) do
      {:ok, %{user: user}} ->
        conn
        |> Bridge.Web.Auth.sign_in(invitation.team, user)
        |> redirect(to: thread_path(conn, :index))

      {:error, :user, changeset, _} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:invitation, invitation)
        |> render(Bridge.Web.InvitationView, "show.html")

      _ ->
        conn
        |> put_flash(:error, "Oops! Something went wrong. Please try again.")
        |> redirect(to: invitation_path(conn, :show, invitation))
    end
  end
end
