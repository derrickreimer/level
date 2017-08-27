defmodule Bridge.TeamsTest do
  use Bridge.DataCase
  use Bamboo.Test

  alias Bridge.Teams

  describe "get_team_by_slug(!)/1" do
    setup do
      insert_signup()
    end

    test "returns the team if found", %{team: team} do
      assert Teams.get_team_by_slug(team.slug).id == team.id
      assert Teams.get_team_by_slug!(team.slug).id == team.id
    end

    test "handles when the team is not found" do
      assert Teams.get_team_by_slug("doesnotexist") == nil

      assert_raise(Ecto.NoResultsError, fn ->
        Teams.get_team_by_slug!("doesnotexist")
      end)
    end
  end

  describe "get_user/1" do
    setup do
      insert_signup()
    end

    test "returns the user if found", %{user: user} do
      assert Teams.get_user(user.id).id == user.id
    end

    test "handles when the user is not found" do
      assert Teams.get_user(99_999) == nil
    end
  end

  describe "get_user_by_identifier/1" do
    setup do
      insert_signup()
    end

    test "looks up user by email address", %{team: team, user: user} do
      assert Teams.get_user_by_identifier(team, user.email).id == user.id
    end

    test "looks up user by username", %{team: team, user: user} do
      assert Teams.get_user_by_identifier(team, user.username).id == user.id
    end

    test "handles when the user is not found", %{team: team} do
      assert Teams.get_user_by_identifier(team, "doesnotexist") == nil
    end
  end

  describe "create_invitation/1" do
    setup do
      {:ok, %{team: team, user: user}} = insert_signup()
      params = valid_invitation_params(%{team: team, invitor: user})
      {:ok, %{team: team, invitor: user, params: params}}
    end

    test "sends an invitation email", %{params: params} do
      changeset = Teams.create_invitation_changeset(params)
      {:ok, invitation} = Teams.create_invitation(changeset)
      assert_delivered_email BridgeWeb.Email.invitation_email(invitation)
    end

    test "returns error when params are invalid", %{params: params} do
      params = Map.put(params, :email, "invalid")
      changeset = Teams.create_invitation_changeset(params)

      {:error, error_changeset} = Teams.create_invitation(changeset)
      assert {:email, {"is invalid", validation: :format}}
        in error_changeset.errors
    end
  end

  describe "get_pending_invitation!/2" do
    setup do
      {:ok, %{team: team, user: user}} = insert_signup()
      params = valid_invitation_params(%{team: team, invitor: user})
      changeset = Teams.create_invitation_changeset(params)
      {:ok, invitation} = Teams.create_invitation(changeset)
      {:ok, %{team: team, invitation: invitation}}
    end

    test "returns pending invitation with a matching token",
      %{invitation: invitation, team: team} do
      assert Teams.get_pending_invitation!(team, invitation.token).id ==
        invitation.id
    end

    test "raises a not found error if invitation is already accepted",
      %{invitation: invitation, team: team} do

      invitation
      |> Ecto.Changeset.change(state: "ACCEPTED")
      |> Repo.update()

      assert_raise(Ecto.NoResultsError, fn ->
        Teams.get_pending_invitation!(team, invitation.token)
      end)
    end
  end

  describe "accept_invitation/2" do
    setup do
      {:ok, %{team: team, user: invitor}} = insert_signup()

      params = valid_invitation_params(%{team: team, invitor: invitor})
      changeset = Teams.create_invitation_changeset(params)
      {:ok, invitation} = Teams.create_invitation(changeset)

      {:ok, %{invitation: invitation}}
    end

    test "creates a user and flag invitation as accepted",
      %{invitation: invitation} do
      params = valid_user_params()

      {:ok, %{user: user, invitation: invitation}} =
        Teams.accept_invitation(invitation, params)

      assert user.email == params.email
      assert invitation.state == "ACCEPTED"
      assert invitation.acceptor_id == user.id
    end

    test "handles invalid params", %{invitation: invitation} do
      params =
        valid_user_params()
        |> Map.put(:username, "i am not valid")

      {:error, failed_operation, _, _} =
        Teams.accept_invitation(invitation, params)

      assert failed_operation == :user
    end
  end
end
