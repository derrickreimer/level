defmodule Level.UsersTest do
  use Level.DataCase, async: true
  use Bamboo.Test

  alias Level.Email
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User
  alias Level.Users
  alias Level.WebPush.Subscription

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
      assert errors == [email: {"is invalid", [validation: :format]}]
    end
  end

  describe "update_user/2" do
    test "saves changes to the user" do
      {:ok, user} = create_user()
      {:ok, updated_user} = Users.update_user(user, %{first_name: "Paul"})
      assert updated_user.first_name == "Paul"
      assert updated_user.id == user.id
    end

    test "propagates name changes to space users" do
      {:ok, %{user: user, space_user: space_user}} = create_user_and_space()
      {:ok, _} = Users.update_user(user, %{first_name: "Paul"})
      assert %SpaceUser{first_name: "Paul"} = Repo.get(SpaceUser, space_user.id)
    end
  end

  describe "create_push_subscription/2" do
    setup do
      {:ok, user} = create_user()
      {:ok, %{user: user}}
    end

    test "inserts the subscription for the user", %{user: %User{id: user_id} = user} do
      # Gracefully handle duplicates
      {:ok, _} = Users.create_push_subscription(user, valid_push_subscription_data("a"))
      {:ok, _} = Users.create_push_subscription(user, valid_push_subscription_data("a"))

      assert %{^user_id => [%Subscription{endpoint: "a"}]} =
               Users.get_push_subscriptions([user_id])

      # A user can have multiple distinct subscriptions
      {:ok, _} = Users.create_push_subscription(user, valid_push_subscription_data("b"))

      data =
        [user.id]
        |> Users.get_push_subscriptions()
        |> Map.values()
        |> List.flatten()
        |> Enum.map(fn sub -> sub.endpoint end)
        |> Enum.sort()

      assert data == ["a", "b"]

      # Multiple users can have the same subscription
      {:ok, %User{id: another_user_id} = another_user} = create_user()
      {:ok, _} = Users.create_push_subscription(another_user, valid_push_subscription_data("a"))

      assert %{^another_user_id => [%Subscription{endpoint: "a"}]} =
               Users.get_push_subscriptions([another_user_id])
    end

    test "returns a parse error if payload is invalid", %{user: user} do
      assert {:error, :parse_error} = Users.create_push_subscription(user, "{")
      assert %{} = Users.get_push_subscriptions([user.id])
    end

    test "returns an invalid keys error if payload has wrong data", %{user: user} do
      assert {:error, :invalid_keys} = Users.create_push_subscription(user, ~s({"foo": "bar"}))
      assert %{} = Users.get_push_subscriptions([user.id])
    end
  end

  describe "initiate_password_reset/1" do
    setup do
      {:ok, user} = create_user()
      {:ok, %{user: user}}
    end

    test "sends a password reset email", %{user: user} do
      {:ok, reset} = Users.initiate_password_reset(user)
      assert_delivered_email(Email.password_reset(user, reset))
    end
  end
end
