defmodule Bridge.Web.AcceptInvitationController do
  use Bridge.Web, :controller

  alias Bridge.Invitation

  plug :fetch_team

  def create(conn, %{"id" => id, "user" => user_params}) do
    # TODO: refactor this out into a plug
    invitation =
      Invitation
      |> Repo.get_by!(team_id: conn.assigns[:team].id, state: "PENDING", token: id)
      |> Repo.preload([:team, :invitor])

    case Invitation.accept(invitation, user_params) do
      {:ok, %{user: _user}} ->
        # sign the user in, redirect accordingly
        conn
      {:error, _, _, _} ->
        # unexpected error occurred
        conn
    end
  end
end
