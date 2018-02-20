defmodule Level.Rooms.RoomTest do
  use Level.DataCase, async: true

  alias Level.Rooms.Room

  describe "create_changeset/2" do
    setup do
      {:ok, %{params: valid_room_params()}}
    end

    test "validates given valid params", %{params: params} do
      assert %Ecto.Changeset{valid?: true} = Room.create_changeset(%Room{}, params)
    end

    test "requires a name", %{params: params} do
      invalid_params = %{params | name: nil}

      assert %Ecto.Changeset{errors: [name: {"can't be blank", [validation: :required]}]} =
               Room.create_changeset(%Room{}, invalid_params)
    end
  end
end
