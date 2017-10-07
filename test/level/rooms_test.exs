defmodule Level.RoomsTest do
  use Level.DataCase

  alias Level.Rooms
  alias Level.Spaces

  describe "create_room/2" do
    setup do
      insert_signup()
    end

    test "creates a room and subscription given a valid params",
      %{space: space, user: user} do
      params = valid_room_params()

      {:ok, %{room: room, room_subscription: subscription}} =
        Rooms.create_room(user, params)

      assert room.space_id == space.id
      assert room.creator_id == user.id
      assert room.name == params.name
      assert room.state == "ACTIVE"

      assert subscription.user_id == user.id
      assert subscription.room_id == room.id
    end

    test "returns an error tuple given invalid params",
      %{user: user} do
      params =
        valid_room_params()
        |> Map.put(:name, nil)

      {:error, :room, changeset, _} = Rooms.create_room(user, params)

      assert %Ecto.Changeset{
        errors: [name: {"can't be blank", [validation: :required]}]
      } = changeset
    end
  end

  describe "get_room_subscription/2" do
    setup do
      insert_signup()
    end

    test "returns the subscription if user is subscribed to the room",
      %{user: user} do
      {:ok, %{room: room}} = Rooms.create_room(user, valid_room_params())
      subscription = Rooms.get_room_subscription(room, user)
      assert subscription.room_id == room.id
      assert subscription.user_id == user.id
    end

    test "returns nil if user is not subscribed to the room",
      %{space: space, user: user} do
      {:ok, %{room: room}} = Rooms.create_room(user, valid_room_params())

      # TODO: implement a helper method for adding a user like this
      {:ok, another_user} =
        %Level.Spaces.User{}
        |> Level.Spaces.User.signup_changeset(valid_user_params())
        |> put_change(:space_id, space.id)
        |> put_change(:role, "MEMBER")
        |> Repo.insert()

      assert Rooms.get_room_subscription(room, another_user) == nil
    end
  end
end
