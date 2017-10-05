defmodule Level.RoomsTest do
  use Level.DataCase

  alias Level.Rooms

  describe "create_room_changeset/2" do
    setup do
      user = %Level.Spaces.User{id: 1, space_id: 9}
      {:ok, %{user: user}}
    end

    test "creates a new changeset and injects relations", %{user: user} do
      params = %{name: "Foo"}
      changeset = Rooms.create_room_changeset(user, params)
      assert %Ecto.Changeset{
        changes: %{creator_id: 1, space_id: 9, name: "Foo"}
      } = changeset
    end
  end

  describe "create_room/2" do
    setup do
      insert_signup()
    end

    test "creates a room given a valid params",
      %{space: space, user: user} do
      params = valid_room_params()

      {:ok, room} = Rooms.create_room(user, params)

      assert room.space_id == space.id
      assert room.creator_id == user.id
      assert room.name == params.name
      assert room.state == "ACTIVE"
    end

    test "returns an error tuple given invalid params",
      %{user: user} do
      params =
        valid_room_params()
        |> Map.put(:name, nil)

      {:error, changeset} = Rooms.create_room(user, params)

      assert %Ecto.Changeset{
        errors: [name: {"can't be blank", [validation: :required]}]
      } = changeset
    end
  end
end
