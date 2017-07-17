defmodule Bridge.InvitationRepoTest do
  use Bridge.DataCase
  use Bamboo.Test

  alias Bridge.Invitation

  describe "create/1" do
    setup do
      {:ok, %{team: team, user: user}} = insert_signup()
      params = valid_invitation_params(%{team: team, invitor: user})
      {:ok, %{team: team, invitor: user, params: params}}
    end

    test "sends an invitation email", %{params: params} do
      {:ok, invitation} = Invitation.create(params)
      assert_delivered_email Bridge.Email.invitation_email(invitation)
    end

    test "returns error when params are invalid", %{params: params} do
      params = Map.put(params, :email, "invalid")
      {:error, changeset} = Invitation.create(params)
      assert {:email, {"is invalid", validation: :format}}
        in changeset.errors
    end
  end
end
