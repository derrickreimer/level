defmodule Bridge.Teams.InvitationRepoTest do
  use Bridge.DataCase
  use Bamboo.Test

  alias Bridge.Teams
  alias Bridge.Teams.Invitation

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

      changeset = Invitation.changeset(%Invitation{}, params)
      {:error, changeset} = Repo.insert(changeset)

      assert {:email, {"already has an invitation", []}}
        in changeset.errors
    end

    test "validate uniqueness when pending and non-matching email case",
      %{team: team, invitor: invitor} do
      params = valid_invitation_params(%{team: team, invitor: invitor})
      changeset = Teams.create_invitation_changeset(params)
      Teams.create_invitation(changeset)

      changeset = Invitation.changeset(%Invitation{},
        %{params | email: String.upcase(params.email)})

      {:error, changeset} = Repo.insert(changeset)

      assert {:email, {"already has an invitation", []}}
        in changeset.errors
    end
  end
end
