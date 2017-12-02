defmodule Level.Rooms do
  @moduledoc """
  A room is place for miscellaneous discussions to occur amongst a group of
  users. Unlike conversations, rooms are designed to be long-lasting threads
  for small disparate discussions.
  """

  alias Level.Repo
  alias Level.Rooms.Room
  alias Level.Rooms.RoomSubscription
  alias Level.Rooms.Message
  alias Ecto.Multi

  import Level.Gettext
  import Ecto.Query, only: [from: 2]

  @doc """
  Fetches a room for a given user by id.

  ## Examples

      # When the room exists and the user can access, returns it.
      # Note: this does not guarantee that the user is actually _subscribed_
      # to the room, only that the user has permisson to see it.
      get_room(user, "999")
      => {:ok, %Room{...}}

      # Otherwise, returns an error.
      get_room(user, "idontexist")
      => {:error, %{message: "Room not found", code: "NOT_FOUND"}}
  """
  def get_room(%Level.Spaces.User{} = user, id) do
    case Repo.get_by(Room, id: id, space_id: user.space_id, state: "ACTIVE") do
      %Room{subscriber_policy: "INVITE_ONLY"} = room ->
        case get_room_subscription(room, user) do
          {:error, _} ->
            not_found(dgettext("errors", "Room not found"))
          {:ok, _} ->
            {:ok, room}
        end
      nil ->
        not_found(dgettext("errors", "Room not found"))
      room ->
        {:ok, room}
    end
  end

  @doc """
  Creates a new room and subscribes the creator to the room.

  ## Examples

      # If operation succeeds, returns a success tuple containing the newly-created
      # room and subscription for the user who created the room.
      create_room(user, %{name: "Development", ...})
      => {:ok, %{room: room, room_subscription: room_subscription}}

      # Otherwise, returns an error.
      => {:error, failed_operation, failed_value, changes_so_far}
  """
  def create_room(user, params \\ %{}) do
    user
    |> create_room_operation(params)
    |> Repo.transaction()
  end

  @doc """
  Transitions a given room to a deleted state.

  ## Examples

      # If operation succeeds, returns success.
      delete_room(%Room{...})
      => {:ok, %Room{...}}

      # Otherwise, returns an error.
      => {:error, %Ecto.Changeset{...}}
  """
  def delete_room(room) do
    Repo.update(Ecto.Changeset.change(room, state: "DELETED"))
  end

  @doc """
  Deletes a given room subscription.

  ## Examples

      # If operation succeeds, returns success.
      delete_room_subscription(%RoomSubscription{...})
      => {:ok, %RoomSubscription{...}}

      # Otherwise, returns an error.
      => {:error, %Ecto.Changeset{...}}
  """
  def delete_room_subscription(%RoomSubscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc """
  Fetches the subscription to a room for a particular user.

  ## Examples

      # If user is subscribed to the room, returns success.
      get_room_subscription(room, user)
      => {:ok, %RoomSubscription{...}}

      # Otherwise, returns an error.
      => {:error, %{message: "...", code: "NOT_FOUND"}}
  """
  def get_room_subscription(room, user) do
    case Repo.get_by(RoomSubscription, room_id: room.id, user_id: user.id) do
      nil ->
        not_found(dgettext("errors", "User is not subscribed to the room"))
      subscription ->
        {:ok, subscription}
    end
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

  ## Examples

      # If successful, returns success.
      subscribe_to_room(room, user)
      => {:ok, %RoomSubscription{...}}

      # If user is already subscribed, returns changeset with errors.
      subscribe_to_room(room, user_already_in_room)
      => {:error, %Ecto.Changeset{
        errors: [user_id: {"is already subscribed to this room", []}]
      }}
  """
  def subscribe_to_room(room, user) do
    room
    |> create_room_subscription_changeset(user)
    |> Repo.insert()
  end

  @doc """
  Posts a new message to a given room.

  ## Examples

      # If the message is valid, returns success.
      create_message(room, user, %{body: "Hello world"})
      => {:ok, %Message{...}}

      # Otherwise, returns an error.
      => {:error, %Ecto.Changeset{...}}
  """
  def create_message(room, user, params \\ %{}) do
    with {:ok, message} <- room
      |> create_room_message_changeset(user, params)
      |> Repo.insert()
    do
      room_member_ids = Repo.all(
        from s in "room_subscriptions",
          where: s.room_id == ^room.id,
          select: s.user_id
      )

      topics = Enum.map(room_member_ids, fn(id) ->
        {:room_message_created, to_string(id)}
      end)

      payload = message_created_payload(room, message)

      Absinthe.Subscription.publish(LevelWeb.Endpoint, payload, topics)

      {:ok, message}
    else
      err -> err
    end
  end

  @doc """
  Builds a payload (to return via GraphQL) when a message is successfully created.
  """
  def message_created_payload(room, message) do
    %{success: true, room: room, room_message: message, errors: []}
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

  # Builds a changeset for creating a room message.
  defp create_room_message_changeset(room, user, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, user.space_id)
      |> Map.put(:user_id, user.id)
      |> Map.put(:room_id, room.id)

    Message.create_changeset(%Message{}, params_with_relations)
  end

  # Builds a "not found" response with a given message
  defp not_found(message) do
    {:error, %{message: message, code: "NOT_FOUND"}}
  end
end
