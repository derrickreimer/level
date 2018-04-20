defmodule Level.UsersTest do
  use Level.DataCase, async: true

  alias Level.Users

  describe "create_user/1" do
    test "creates a new user given valid params" do
      params =
        valid_user_params()
        |> Map.put(:first_name, "Derrick")

      {:ok, user} = Users.create_user(params)
      assert user.first_name == "Derrick"
    end

    test "requires a valid email address" do
      params =
        valid_user_params()
        |> Map.put(:email, "invalid")

      {:error, %Ecto.Changeset{errors: errors}} = Users.create_user(params)
      assert errors == []
    end
  end
end
