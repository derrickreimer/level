defmodule Neuron.Teams.InvitationRepoTest do
  use Neuron.DataCase
  use Bamboo.Test

  alias Neuron.Teams
  alias Neuron.Teams.Invitation

  describe "changeset/2" do
    setup do
      {:ok, %{team: team, user: invitor}} = insert_signup()
      {:ok, %{team: team, invitor: invitor}}
    end

    test "validate uniqueness when pending and matching email case",
      %{team: team, invitor: invitor} do
      params = valid_invitation_params(%{team: team, invitor: invitor})
      changeset = Teams.create_invitation_changeset(params)
      Teams.create_invitation(changeset)

      changeset2 = Invitation.changeset(%Invitation{}, params)
      {:error, error_changeset} = Repo.insert(changeset2)

      assert {:email, {"already has an invitation", []}}
        in error_changeset.errors
    end

    test "validate uniqueness when pending and non-matching email case",
      %{team: team, invitor: invitor} do
      params = valid_invitation_params(%{team: team, invitor: invitor})
      changeset = Teams.create_invitation_changeset(params)
      Teams.create_invitation(changeset)

      changeset2 = Invitation.changeset(%Invitation{},
        %{params | email: String.upcase(params.email)})

      {:error, error_changeset} = Repo.insert(changeset2)

      assert {:email, {"already has an invitation", []}}
        in error_changeset.errors
    end
  end
end
