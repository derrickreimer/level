defmodule Level.Users.UserTest do
  use Level.DataCase, async: true

  alias Level.Schemas.User

  describe "create_changeset/2" do
    test "validates with valid data" do
      changeset = User.create_changeset(%User{}, valid_user_params())
      assert changeset.valid?
    end

    test "sets the default time zone if one is not provided" do
      {_value, params} = Map.pop(valid_user_params(), :time_zone)
      changeset = User.create_changeset(%User{}, params)
      %{time_zone: time_zone} = changeset.changes

      assert changeset.valid?
      assert time_zone == "UTC"
    end

    test "sets the default time zone if provided value is blank" do
      params = Map.put(valid_user_params(), :time_zone, "")
      changeset = User.create_changeset(%User{}, params)
      %{time_zone: time_zone} = changeset.changes

      assert changeset.valid?
      assert time_zone == "UTC"
    end

    test "hashes the password" do
      changeset = User.create_changeset(%User{}, valid_user_params())
      %{password: password, password_hash: password_hash} = changeset.changes

      assert password_hash
      assert Comeonin.Bcrypt.checkpw(password, password_hash)
    end

    test "sets random session salt" do
      changeset = User.create_changeset(%User{}, valid_user_params())
      %{session_salt: salt} = changeset.changes
      assert String.length(salt) == 32
    end
  end

  describe "email_format/0" do
    test "matches valid email addresses" do
      assert Regex.match?(User.email_format(), "derrick@gmail.com")
      assert Regex.match?(User.email_format(), "der-rick@gmail.com")
      assert Regex.match?(User.email_format(), "der.ric%k@gmail.co")
      assert Regex.match?(User.email_format(), "derrick+123@level.live")
      assert Regex.match?(User.email_format(), "OLDERGENTLEMAN@GMAIL.COM")
    end

    test "does not match invalid addresses" do
      refute Regex.match?(User.email_format(), "der rick@gmail.com")
      refute Regex.match?(User.email_format(), "foo@")
    end
  end
end
