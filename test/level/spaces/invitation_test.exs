defmodule Level.Spaces.InvitationTest do
  use Level.DataCase, async: true

  alias Level.Spaces.Invitation

  describe "changeset/2" do
    test "generates a unique token" do
      changeset = Invitation.changeset(%Invitation{}, valid_invitation_params())
      %{token: token} = changeset.changes

      assert token != nil
    end

    test "requires a valid email address" do
      params = Map.put(valid_invitation_params(), :email, "invalid")
      changeset = Invitation.changeset(%Invitation{}, params)
      assert {:email, {"is invalid", validation: :format}} in changeset.errors
    end

    test "requires an email address" do
      params = Map.put(valid_invitation_params(), :email, nil)
      changeset = Invitation.changeset(%Invitation{}, params)
      assert {:email, {"can't be blank", validation: :required}} in changeset.errors
    end

    # See InvitationRepoTest for more tests involving uniqueness constraints
  end
end
