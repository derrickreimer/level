defmodule Level.UsersTest do
  use Level.DataCase, async: true

  alias Level.Spaces.SpaceUser
  alias Level.Users
  alias Level.Users.PushSubscription

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

    test "inserts the subscription for the user", %{user: user} do
      {:ok, "a"} = Users.create_push_subscription(user, "a")
      assert [%PushSubscription{data: "a"}] = Users.get_push_subscriptions(user.id)

      # Gracefully handle duplicates
      {:ok, "a"} = Users.create_push_subscription(user, "a")
      assert [%PushSubscription{data: "a"}] = Users.get_push_subscriptions(user.id)

      # A user can have multiple distinct subscriptions
      {:ok, "b"} = Users.create_push_subscription(user, "b")

      data =
        user.id
        |> Users.get_push_subscriptions()
        |> Enum.map(fn sub -> sub.data end)
        |> Enum.sort()

      assert data == ["a", "b"]

      # Multiple users can have the same subscription
      {:ok, another_user} = create_user()
      {:ok, "a"} = Users.create_push_subscription(another_user, "a")
      assert [%PushSubscription{data: "a"}] = Users.get_push_subscriptions(another_user.id)
    end
  end
end
