defmodule Level.RoomsTest do
  use Level.DataCase

  alias Level.Rooms
  alias Level.Spaces

  describe "create_room/2" do
    setup do
      insert_signup()
    end

    test "creates a room and subscription given a valid params", %{space: space, user: user} do
      params = valid_room_params()

      {:ok, %{room: room, room_subscription: subscription}} = Rooms.create_room(user, params)

      assert room.space_id == space.id
      assert room.creator_id == user.id
      assert room.name == params.name
      assert room.state == "ACTIVE"

      assert subscription.user_id == user.id
      assert subscription.room_id == room.id
    end

    test "returns an error tuple given invalid params", %{user: user} do
      params =
        valid_room_params()
        |> Map.put(:name, nil)

      {:error, :room, changeset, _} = Rooms.create_room(user, params)

      assert %Ecto.Changeset{
               errors: [name: {"can't be blank", [validation: :required]}]
             } = changeset
    end
  end

  describe "update_room/2" do
    setup do
      {:ok, %{user: user}} = insert_signup()
      {:ok, %{room: room}} = insert_room(user)
      {:ok, user: user, room: room}
    end

    test "updates a room given valid params", %{room: room} do
      params = %{name: "New Name"}
      {:ok, new_room} = Rooms.update_room(room, params)
      assert new_room.name == "New Name"
    end
  end

  describe "get_room_subscription/2" do
    setup do
      insert_signup()
    end

    test "returns the subscription if user is subscribed to the room", %{user: user} do
      {:ok, %{room: room}} = Rooms.create_room(user, valid_room_params())
      {:ok, subscription} = Rooms.get_room_subscription(room.id, user.id)
      assert subscription.room_id == room.id
      assert subscription.user_id == user.id
    end

    test "returns an error if user is not subscribed to the room", %{space: space, user: user} do
      {:ok, %{room: room}} = Rooms.create_room(user, valid_room_params())

      # TODO: implement a helper method for adding a user like this
      {:ok, another_user} =
        %Spaces.User{}
        |> Spaces.User.signup_changeset(valid_user_params())
        |> put_change(:space_id, space.id)
        |> put_change(:role, "MEMBER")
        |> Repo.insert()

      assert {:error, _} = Rooms.get_room_subscription(room.id, another_user.id)
    end
  end

  describe "get_room/2" do
    setup do
      create_user_and_room()
    end

    test "returns the room if the user has access", %{user: user, room: room} do
      {:ok, %Rooms.Room{id: fetched_room_id}} = Rooms.get_room(user, room.id)
      assert fetched_room_id == room.id
    end

    test "returns the room if the room is public", %{user: user, room: room} do
      # delete the subscription
      Repo.delete_all(Rooms.RoomSubscription)
      {:ok, %Rooms.Room{id: fetched_room_id}} = Rooms.get_room(user, room.id)
      assert fetched_room_id == room.id
    end

    test "returns an error if room has been deleted", %{user: user, room: room} do
      Rooms.delete_room(room)
      assert {:error, _} = Rooms.get_room(user, room.id)
    end

    test "returns an error if room does not exist", %{user: user, room: room} do
      Repo.delete_all(Rooms.RoomSubscription)
      Repo.delete(room)
      assert {:error, _} = Rooms.get_room(user, room.id)
    end

    test "returns an error if the room is invite-only and user doesn't have access", %{
      user: user,
      room: room
    } do
      # TODO: Implement an #update_policy function and use that here
      Repo.update(Ecto.Changeset.change(room, subscriber_policy: "INVITE_ONLY"))
      {:ok, subscription} = Rooms.get_room_subscription(room.id, user.id)
      Rooms.delete_room_subscription(subscription)
      assert {:error, _} = Rooms.get_room(user, room.id)
    end
  end

  describe "delete_room/1" do
    setup do
      create_user_and_room()
    end

    test "sets state to deleted", %{room: room} do
      assert {:ok, %Rooms.Room{state: "DELETED"}} = Rooms.delete_room(room)
    end
  end

  describe "delete_room_subscription/1" do
    setup do
      create_user_and_room()
    end

    test "deletes the room subscription record", %{user: user, room: room} do
      {:ok, subscription} = Rooms.get_room_subscription(room.id, user.id)
      {:ok, _} = Rooms.delete_room_subscription(subscription)
      assert {:error, _} = Rooms.get_room_subscription(room.id, user.id)
    end
  end

  describe "get_message/2" do
    setup do
      create_user_and_room()
    end

    test "returns the message if it exists", %{room: room, room_subscription: subscription} do
      params = valid_room_message_params()
      {:ok, %{room_message: message}} = Rooms.create_message(subscription, params)
      {:ok, result} = Rooms.get_message(room, message.id)
      assert result.id == message.id
    end

    test "returns an error if message is not found", %{room: room} do
      {:error, result} = Rooms.get_message(room, "9999999")
      assert result == %{code: "NOT_FOUND", message: "Message not found"}
    end
  end

  describe "create_message/3" do
    setup do
      create_user_and_room()
    end

    test "creates a message given valid params", %{room_subscription: subscription} do
      params = valid_room_message_params()
      {:ok, %{room_message: message}} = Rooms.create_message(subscription, params)
      assert message.user_id == subscription.user_id
      assert message.room_id == subscription.room_id
      assert message.body == params.body
    end

    test "sets the last read room message", %{room_subscription: subscription} do
      params = valid_room_message_params()

      {:ok, %{room_message: message, room_subscription: updated_subscription}} =
        Rooms.create_message(subscription, params)

      assert updated_subscription.last_read_message_id == message.id
    end

    test "returns an error with changeset if invalid", %{room_subscription: subscription} do
      params =
        valid_room_message_params()
        |> Map.put(:body, nil)

      {:error, changeset} = Rooms.create_message(subscription, params)

      assert %Ecto.Changeset{
               errors: [body: {"can't be blank", [validation: :required]}]
             } = changeset
    end
  end

  describe "get_last_message/3" do
    setup do
      create_user_and_room()
    end

    test "returns nil when there are no room messages", %{room: room} do
      {:ok, message} = Rooms.get_last_message(room)
      assert message == nil
    end

    test "returns the most recent message", %{room: room, room_subscription: subscription} do
      params = valid_room_message_params()

      {:ok, %{room_message: message1}} = Rooms.create_message(subscription, params)
      {:ok, %{room_message: message2}} = Rooms.create_message(subscription, params)

      Repo.update(Ecto.Changeset.change(message1, %{inserted_at: ~N[2018-02-08 00:10:00]}))
      Repo.update(Ecto.Changeset.change(message2, %{inserted_at: ~N[2018-02-08 00:00:00]}))

      {:ok, message} = Rooms.get_last_message(room)
      assert message.id == message1.id
    end
  end

  describe "mark_message_as_read/2" do
    setup do
      {:ok, %{user: user, room: room, room_subscription: room_subscription}} =
        create_user_and_room()

      {:ok, %{room_message: message, room_subscription: room_subscription}} =
        Rooms.create_message(room_subscription, valid_room_message_params())

      {:ok, %{user: user, message: message, room: room, room_subscription: room_subscription}}
    end

    test "sets the last read message state", %{
      message: message,
      room_subscription: room_subscription
    } do
      # Forcibly ensure that there is not last read message set on the subscription
      {:ok, room_subscription} =
        room_subscription
        |> Ecto.Changeset.change(last_read_message_id: nil)
        |> Repo.update()

      {:ok, updated_subscription} = Rooms.mark_message_as_read(room_subscription, message)

      assert updated_subscription.last_read_message_id == message.id
    end

    test "does not set the last read message state if message is old", %{
      message: old_message,
      room_subscription: room_subscription
    } do
      {:ok, %{room_message: new_message, room_subscription: room_subscription}} =
        Rooms.create_message(room_subscription, valid_room_message_params())

      {:ok, updated_subscription} = Rooms.mark_message_as_read(room_subscription, old_message)

      # verify that monatonicity is maintained
      assert old_message.id < new_message.id
      assert updated_subscription.last_read_message_id == new_message.id
    end
  end

  describe "message_created_payload/2" do
    setup do
      {:ok, %{room: %Rooms.Room{}, message: %Rooms.Message{}}}
    end

    test "builds a GraphQL payload", %{room: room, message: message} do
      assert Rooms.message_created_payload(room, message) == %{
               success: true,
               room: room,
               room_message: message,
               errors: []
             }
    end
  end

  describe "subscribe_to_room/2" do
    setup do
      {:ok, %{user: owner, room: room, space: space}} = create_user_and_room()
      {:ok, another_user} = insert_member(space)
      {:ok, %{owner: owner, room: room, user: another_user}}
    end

    test "creates a room subscription if not already subscribed", %{room: room, user: user} do
      {:ok, subscription} = Rooms.subscribe_to_room(room, user)
      assert subscription.user_id == user.id
      assert subscription.room_id == room.id
    end

    test "returns an error if already subscribed", %{room: room, owner: owner} do
      {:error, %Ecto.Changeset{errors: errors}} = Rooms.subscribe_to_room(room, owner)

      assert errors == [user_id: {"is already subscribed to this room", []}]
    end
  end

  describe "get_mandatory_rooms/1" do
    setup do
      {:ok, %{user: user, default_room: %{room: room}}} = insert_signup()
      {:ok, %{default_room: %{room: room_in_other_space}}} = insert_signup()
      {:ok, %{user: user, room: room, room_in_other_space: room_in_other_space}}
    end

    test "returns mandatory rooms in the user's space", %{
      user: user,
      room: room,
      room_in_other_space: room_in_other_space
    } do
      room_ids = Enum.map(Rooms.get_mandatory_rooms(user), fn item -> item.id end)
      assert Enum.member?(room_ids, room.id)
      refute Enum.member?(room_ids, room_in_other_space.id)
    end
  end

  defp create_user_and_room do
    {:ok, %{user: user, space: space}} = insert_signup()

    {:ok, %{room: room, room_subscription: room_subscription}} =
      Rooms.create_room(user, valid_room_params())

    {:ok, %{user: user, room: room, room_subscription: room_subscription, space: space}}
  end
end
