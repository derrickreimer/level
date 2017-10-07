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

  @doc """
  Fetches the subscription to a room for a particular user. If no subscription
  exists, returns nil.
  """
  def get_room_subscription(room, user) do
    Repo.get_by(RoomSubscription, room_id: room.id, user_id: user.id)
  end

  @doc """
  Fetches all mandatory rooms for a given user and returns a list.
  """
  def get_mandatory_rooms(%Level.Spaces.User{space_id: space_id}) do
    Repo.all(Room,
      space_id: space_id,
      subscriber_policy: "MANDATORY"
    )
  end

  @doc """
  Subscribes a given user to all rooms designated as mandatory.
  """
  def subscribe_to_mandatory_rooms(user) do
    for room <- get_mandatory_rooms(user) do
      subscribe_to_room(room, user)
    end
  end

  @doc """
  Subscribes a given user to a given room.
  """
  def subscribe_to_room(room, user) do
    room
    |> create_room_subscription_changeset(user)
    |> Repo.insert()
  end

  # Builds an operation to create a new room. Specifically, this operation
  # inserts a new record in the rooms table and, provided that succeeds,
  # inserts a new record into the room subscriptions table for the user that
  # created the room.
  defp create_room_operation(user, params) do
    Multi.new
    |> Multi.insert(:room, create_room_changeset(user, params))
    |> Multi.run(:room_subscription, create_room_subscription_operation(user))
  end

  # Returns a function that creates a room subscription.
  # For use in an `Ecto.Multi` pipeline.
  defp create_room_subscription_operation(user) do
    fn %{room: room} ->
      subscribe_to_room(room, user)
    end
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
