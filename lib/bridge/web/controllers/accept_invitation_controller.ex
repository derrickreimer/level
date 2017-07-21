defmodule Bridge.Web.AcceptInvitationController do
  use Bridge.Web, :controller

  alias Bridge.Invitation
  alias Bridge.User

  plug :fetch_team

  def create(conn, %{"id" => id, "user" => user_params}) do
    # TODO: refactor this out into a plug
    invitation =
      Invitation
      |> Repo.get_by!(team_id: conn.assigns[:team].id, state: "PENDING", token: id)
      |> Repo.preload([:team, :invitor])

    user_params =
      user_params
      |> Map.put(:team_id, invitation.team_id)
      # |> Map.put(:role, invitation.role)

    changeset = User.signup_changeset(%{}, user_params)

    case Invitation.accept(invitation, changeset) do
      {:ok, %{user: _user}} ->
        # sign the user in, redirect accordingly
        conn
      {:error, _, _, _} ->
        # unexpected error occurred
        conn
    end
  end
end
