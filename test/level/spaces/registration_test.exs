defmodule Level.Spaces.RegistrationTest do
  use Level.DataCase, async: true

  alias Level.Spaces.Registration

  describe "changeset/2" do
    test "validates with valid data" do
      changeset = Registration.changeset(%{}, valid_signup_params())
      assert changeset.valid?
    end

    test "requires a space name" do
      params = Map.put(valid_signup_params(), :space_name, "")
      changeset = Registration.changeset(%{}, params)
      assert {:space_name, {"can't be blank", validation: :required}} in changeset.errors
    end

    test "requires a first name" do
      params = Map.put(valid_signup_params(), :first_name, "")
      changeset = Registration.changeset(%{}, params)
      assert {:first_name, {"can't be blank", validation: :required}} in changeset.errors
    end

    test "requires a last name" do
      params = Map.put(valid_signup_params(), :last_name, "")
      changeset = Registration.changeset(%{}, params)
      assert {:last_name, {"can't be blank", validation: :required}} in changeset.errors
    end

    test "requires an email" do
      params = Map.put(valid_signup_params(), :email, "")
      changeset = Registration.changeset(%{}, params)
      assert {:email, {"can't be blank", validation: :required}} in changeset.errors
    end

    test "requires a space name no longer than 255 chars" do
      params = Map.put(valid_signup_params(), :space_name, String.duplicate("a", 256))
      changeset = Registration.changeset(%{}, params)

      assert {:space_name,
              {"should be at most %{count} character(s)",
               count: 255, validation: :length, max: 255}} in changeset.errors
    end

    test "requires a first name no longer than 255 chars" do
      params = Map.put(valid_signup_params(), :first_name, String.duplicate("a", 256))
      changeset = Registration.changeset(%{}, params)

      assert {:first_name,
              {"should be at most %{count} character(s)",
               count: 255, validation: :length, max: 255}} in changeset.errors
    end

    test "requires a last name no longer than 255 chars" do
      params = Map.put(valid_signup_params(), :last_name, String.duplicate("a", 256))
      changeset = Registration.changeset(%{}, params)

      assert {:last_name,
              {"should be at most %{count} character(s)",
               count: 255, validation: :length, max: 255}} in changeset.errors
    end

    test "requires a password" do
      params = Map.put(valid_signup_params(), :password, "")
      changeset = Registration.changeset(%{}, params)
      assert {:password, {"can't be blank", validation: :required}} in changeset.errors
    end

    test "requires a password at least 6 chars long" do
      params = Map.put(valid_signup_params(), :password, "12345")
      changeset = Registration.changeset(%{}, params)

      assert {:password,
              {"should be at least %{count} character(s)", count: 6, validation: :length, min: 6}} in changeset.errors
    end

    test "requires a valid slug" do
      params = Map.put(valid_signup_params(), :slug, "$upercool")
      changeset = Registration.changeset(%{}, params)

      assert {:slug, {"must be lowercase and alphanumeric", validation: :format}} in changeset.errors
    end

    test "requires a valid email" do
      params = Map.put(valid_signup_params(), :email, "derrick@nowhere")
      changeset = Registration.changeset(%{}, params)
      assert {:email, {"is invalid", validation: :format}} in changeset.errors
    end
  end
end
