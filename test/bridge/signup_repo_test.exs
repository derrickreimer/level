defmodule Bridge.SignupRepoTest do
  use Bridge.DataCase

  alias Bridge.Signup

  describe "form_changeset/2" do
    test "requires a unique slug" do
      insert_signup(%{slug: "foo"})
      params = Map.put(valid_signup_params(), :slug, "foo")
      changeset = Signup.form_changeset(%{}, params)
      assert {:slug, {"is already taken", validation: :uniqueness}}
        in changeset.errors
    end
  end
end
