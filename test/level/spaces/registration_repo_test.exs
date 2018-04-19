defmodule Level.Spaces.RegistrationRepoTest do
  use Level.DataCase, async: true

  alias Level.Spaces.Registration

  describe "form_changeset/2" do
    test "requires a unique slug" do
      create_user_and_space(%{slug: "foo"})
      params = Map.put(valid_signup_params(), :slug, "foo")
      changeset = Registration.changeset(%{}, params)
      assert {:slug, {"is already taken", validation: :uniqueness}} in changeset.errors
    end
  end
end
