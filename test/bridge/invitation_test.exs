defmodule Bridge.InvitationTest do
  use Bridge.DataCase, async: true

  alias Bridge.Invitation

  describe "changeset/2" do
    setup do
      team = %Bridge.Team{id: 1}
      invitor = %Bridge.User{id: 1}
      {:ok, %{team: team, invitor: invitor}}
    end

    test "sets the initial state", %{team: team, invitor: invitor} do
      changeset = Invitation.changeset(%Invitation{},
        valid_invitation_params(%{team: team, invitor: invitor}))
      %{state: state} = changeset.changes

      assert state == 0
    end

    test "generates a unique token", %{team: team, invitor: invitor} do
      changeset = Invitation.changeset(%Invitation{},
        valid_invitation_params(%{team: team, invitor: invitor}))
      %{token: token} = changeset.changes

      assert token != nil
    end

    test "requires a valid email address", %{team: team, invitor: invitor} do
      params = Map.put(valid_invitation_params(%{team: team, invitor: invitor}), :email, "invalid")
      changeset = Invitation.changeset(%Invitation{}, params)
      assert {:email, {"is invalid", validation: :format}}
        in changeset.errors
    end

    test "requires an email address", %{team: team, invitor: invitor} do
      params = Map.put(valid_invitation_params(%{team: team, invitor: invitor}), :email, nil)
      changeset = Invitation.changeset(%Invitation{}, params)
      assert {:email, {"can't be blank", validation: :required}}
        in changeset.errors
    end
  end
end
