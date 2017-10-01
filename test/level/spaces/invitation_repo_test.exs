defmodule Level.Spaces.InvitationRepoTest do
  use Level.DataCase
  use Bamboo.Test

  alias Level.Spaces
  alias Level.Spaces.Invitation

  describe "changeset/2" do
    setup do
      {:ok, %{space: space, user: invitor}} = insert_signup()
      {:ok, %{space: space, invitor: invitor}}
    end

    test "validate uniqueness when pending and matching email case",
      %{space: space, invitor: invitor} do
      params = valid_invitation_params(%{space: space, invitor: invitor})
      changeset = Spaces.create_invitation_changeset(params)
      Spaces.create_invitation(changeset)

      changeset2 = Invitation.changeset(%Invitation{}, params)
      {:error, error_changeset} = Repo.insert(changeset2)

      assert {:email, {"already has an invitation", []}}
        in error_changeset.errors
    end

    test "validate uniqueness when pending and non-matching email case",
      %{space: space, invitor: invitor} do
      params = valid_invitation_params(%{space: space, invitor: invitor})
      changeset = Spaces.create_invitation_changeset(params)
      Spaces.create_invitation(changeset)

      changeset2 = Invitation.changeset(%Invitation{},
        %{params | email: String.upcase(params.email)})

      {:error, error_changeset} = Repo.insert(changeset2)

      assert {:email, {"already has an invitation", []}}
        in error_changeset.errors
    end
  end
end
