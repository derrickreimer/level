defmodule Level.Teams.RegistrationRepoTest do
  use Level.DataCase

  alias Level.Teams.Registration

  describe "form_changeset/2" do
    test "requires a unique slug" do
      insert_signup(%{slug: "foo"})
      params = Map.put(valid_signup_params(), :slug, "foo")
      changeset = Registration.changeset(%{}, params)
      assert {:slug, {"is already taken", validation: :uniqueness}}
        in changeset.errors
    end
  end
end
