defmodule Level.RoomsTest do
  use Level.DataCase

  alias Level.Rooms

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
end
