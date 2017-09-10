defmodule Neuron.Teams.InvitationTest do
  use Neuron.DataCase, async: true

  alias Neuron.Teams.Invitation

  describe "changeset/2" do
    setup do
      team = %Neuron.Teams.Team{id: 1}
      invitor = %Neuron.Teams.User{id: 1}
      {:ok, %{team: team, invitor: invitor}}
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

    # See InvitationRepoTest for more tests involving uniqueness constraints
  end
end
