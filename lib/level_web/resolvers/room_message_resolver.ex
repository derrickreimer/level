defmodule LevelWeb.RoomMessageResolver do
  @moduledoc """
  GraphQL query resolution for room messages.
  """

  import LevelWeb.ResolverHelpers
  alias Level.Rooms

  def create(args, %{context: %{current_user: user}}) do
    case Rooms.get_room(user, args.room_id) do
      {:ok, room} ->
        resp =
          case Rooms.create_message(room, user, args) do
            {:ok, message} ->
              Rooms.message_created_payload(room, message)
            {:error, changeset} ->
              %{success: false, room: room, room_message: nil, errors: format_errors(changeset)}
          end

        {:ok, resp}

      # Display a top level error if the room is not found
      error -> error
    end
  end

  def mark_as_read(%{room_id: room_id, message_id: message_id}, %{context: %{current_user: user}}) do
    with {:ok, room} <- Rooms.get_room(user, room_id),
         {:ok, subscription} <- Rooms.get_room_subscription(room, user),
         {:ok, message} <- Rooms.get_message(room, message_id)
    do
      resp =
        case Rooms.mark_message_as_read(subscription, message) do
          {:ok, subscription} ->
            %{success: true, room_subscription: subscription, errors: []}

          {:error, changeset} ->
            %{success: false, room_subscription: subscription, errors: format_errors(changeset)}
        end

      {:ok, resp}
    else
      error -> error
    end
  end
end
