defmodule Level.Rooms do
  @moduledoc """
  A room is place for miscellaneous discussions to occur amongst a group of
  users. Unlike conversations, rooms are designed to be long-lasting threads
  for small disparate discussions.
  """

  alias Level.Repo
  alias Level.Rooms.Room
  alias Level.Rooms.RoomSubscription
  alias Ecto.Multi

  @doc """
  Creates a new room and subscribes the creator to the room. If successful,
  returns a tuple of the form `{:ok, %{room: room, room_subscription: room_subscription}}`.
  """
  def create_room(user, params \\ %{}) do
    user
    |> create_room_operation(params)
    |> Repo.transaction()
  end

  # Builds an operation to create a new room. Specifically, this operation
  # inserts a new record in the rooms table and, provided that succeeds,
  # inserts a new record into the room subscriptions table for the user that
  # created the room.
  defp create_room_operation(user, params) do
    Multi.new
    |> Multi.insert(:room, create_room_changeset(user, params))
    |> Multi.run(:room_subscription, fn %{room: room} ->
      room
      |> create_room_subscription_changeset(user)
      |> Repo.insert()
    end)
  end

  # Builds a changeset for creating a new room.
  defp create_room_changeset(user, params) do
    params_with_relations =
      params
      |> Map.put(:creator_id, user.id)
      |> Map.put(:space_id, user.space_id)

    Room.create_changeset(%Room{}, params_with_relations)
  end

  # Builds a changeset for creating a new room subscription.
  defp create_room_subscription_changeset(room, user) do
    RoomSubscription.create_changeset(%RoomSubscription{},
      %{space_id: user.space_id, user_id: user.id, room_id: room.id})
  end
end
