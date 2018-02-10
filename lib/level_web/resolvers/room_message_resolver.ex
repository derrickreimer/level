defmodule LevelWeb.RoomMessageResolver do
  @moduledoc """
  GraphQL query resolution for room messages.
  """

  import LevelWeb.ResolverHelpers
  alias Level.Rooms

  def create(%{room_id: room_id} = args, %{context: %{current_user: user}}) do
    with {:ok, room} <- Rooms.get_room(user, room_id),
         {:ok, subscription} <- Rooms.get_room_subscription(room.id, user.id)
    do
      resp =
        case Rooms.create_message(subscription, args) do
          {:ok, %{room_message: message}} ->
            Rooms.message_created_payload(room, message)
          {:error, changeset} ->
            %{success: false, room: room, room_message: nil, errors: format_errors(changeset)}
        end

      {:ok, resp}

    else
      error -> error
    end
  end

  def mark_as_read(%{room_id: room_id, message_id: message_id}, %{context: %{current_user: user}}) do
    with {:ok, room} <- Rooms.get_room(user, room_id),
         {:ok, subscription} <- Rooms.get_room_subscription(room.id, user.id),
         {:ok, message} <- Rooms.get_message(room, message_id)
    do
      resp =
        case Rooms.mark_message_as_read(subscription, message) do
          {:ok, subscription} ->
            Rooms.mark_message_as_read_payload(subscription)

          {:error, changeset} ->
            %{success: false, room_subscription: subscription, errors: format_errors(changeset)}
        end

      {:ok, resp}
    else
      error -> error
    end
  end
end
