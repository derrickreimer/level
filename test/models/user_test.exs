defmodule Bridge.UserTest do
  use Bridge.ModelCase, async: true

  alias Bridge.User

  describe "signup_changeset/2" do
    test "validates with valid data" do
      changeset = User.signup_changeset(%User{}, valid_signup_params())
      assert changeset.valid?
    end

    test "sets the default time zone if one is not provided" do
      {_value, params} = Map.pop(valid_signup_params(), :time_zone)
      changeset = User.signup_changeset(%User{}, params)
      %{time_zone: time_zone} = changeset.changes

      assert changeset.valid?
      assert time_zone == "UTC"
    end

    test "sets the default time zone if provided value is blank" do
      params = Map.put(valid_signup_params(), :time_zone, "")
      changeset = User.signup_changeset(%User{}, params)
      %{time_zone: time_zone} = changeset.changes

      assert changeset.valid?
      assert time_zone == "UTC"
    end

    test "hashes the password" do
      changeset = User.signup_changeset(%User{}, valid_signup_params())
      %{password: password, password_hash: password_hash} = changeset.changes

      assert password_hash
      assert Comeonin.Bcrypt.checkpw(password, password_hash)
    end

    test "sets the initial state" do
      changeset = User.signup_changeset(%User{}, valid_signup_params())
      %{state: state} = changeset.changes

      assert state == 0
    end

    test "sets the initial role" do
      changeset = User.signup_changeset(%User{}, valid_signup_params())
      %{role: role} = changeset.changes

      assert role == 0
    end
  end

  describe "username_format/0" do
    test "matches lowercase alphanumeric, dot, and dash chars" do
      assert Regex.match?(User.username_format, "derrick")
      assert Regex.match?(User.username_format, "derrick-reimer")
      assert Regex.match?(User.username_format, "derrick.reimer")
    end

    test "does not match whitespace" do
      refute Regex.match?(User.username_format, "derrick reimer")
    end

    test "does not match trailing dashes or dots" do
      refute Regex.match?(User.username_format, "derrick-")
      refute Regex.match?(User.username_format, "derrick.")
    end

    test "does not match leading numbers, dashes or dots" do
      refute Regex.match?(User.username_format, "-derrick")
      refute Regex.match?(User.username_format, ".derrick")
      refute Regex.match?(User.username_format, "8derrick")
    end

    test "does not match special chars" do
      refute Regex.match?(User.username_format, "derr$ick")
    end

    test "does not match uppercase chars" do
      refute Regex.match?(User.username_format, "DerRick")
    end
  end

  describe "email_format/0" do
    test "matches valid email addresses" do
      assert Regex.match?(User.email_format, "derrick@gmail.com")
      assert Regex.match?(User.email_format, "der-rick@gmail.com")
      assert Regex.match?(User.email_format, "der.ric%k@gmail.co")
      assert Regex.match?(User.email_format, "derrick+123@bridge.chat")
      assert Regex.match?(User.email_format, "OLDERGENTLEMAN@GMAIL.COM")
    end

    test "does not match invalid addresses" do
      refute Regex.match?(User.email_format, "der rick@gmail.com")
      refute Regex.match?(User.email_format, "foo@")
    end
  end
end
