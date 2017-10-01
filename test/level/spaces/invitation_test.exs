defmodule Level.Spaces.InvitationTest do
  use Level.DataCase, async: true

  alias Level.Spaces.Invitation

  describe "changeset/2" do
    setup do
      space = %Level.Spaces.Space{id: 1}
      invitor = %Level.Spaces.User{id: 1}
      {:ok, %{space: space, invitor: invitor}}
    end

    test "generates a unique token", %{space: space, invitor: invitor} do
      changeset = Invitation.changeset(%Invitation{},
        valid_invitation_params(%{space: space, invitor: invitor}))
      %{token: token} = changeset.changes

      assert token != nil
    end

    test "requires a valid email address", %{space: space, invitor: invitor} do
      params = Map.put(valid_invitation_params(%{space: space, invitor: invitor}), :email, "invalid")
      changeset = Invitation.changeset(%Invitation{}, params)
      assert {:email, {"is invalid", validation: :format}}
        in changeset.errors
    end

    test "requires an email address", %{space: space, invitor: invitor} do
      params = Map.put(valid_invitation_params(%{space: space, invitor: invitor}), :email, nil)
      changeset = Invitation.changeset(%Invitation{}, params)
      assert {:email, {"can't be blank", validation: :required}}
        in changeset.errors
    end

    # See InvitationRepoTest for more tests involving uniqueness constraints
  end
end
