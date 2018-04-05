defmodule Level.Spaces.InvitationRepoTest do
  use Level.DataCase, async: true
  use Bamboo.Test

  alias Level.Spaces

  describe "changeset/2" do
    setup do
      {:ok, %{space: space, user: invitor}} = insert_signup()
      {:ok, %{space: space, invitor: invitor}}
    end

    test "validate uniqueness when pending and matching email case", %{invitor: invitor} do
      params = valid_invitation_params()
      Spaces.create_invitation(invitor, params)

      {:error, error_changeset} = Spaces.create_invitation(invitor, params)

      assert {:email, {"already has an invitation", []}} in error_changeset.errors
    end

    test "validate uniqueness when pending and non-matching email case", %{invitor: invitor} do
      params = valid_invitation_params()
      Spaces.create_invitation(invitor, params)

      {:error, error_changeset} =
        Spaces.create_invitation(invitor, %{params | email: String.upcase(params.email)})

      assert {:email, {"already has an invitation", []}} in error_changeset.errors
    end
  end
end
