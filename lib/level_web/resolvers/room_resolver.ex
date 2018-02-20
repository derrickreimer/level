defmodule LevelWeb.RoomResolver do
  @moduledoc """
  GraphQL query resolution for rooms.
  """

  import LevelWeb.ResolverHelpers
  import Level.Gettext
  alias Level.Rooms

  def create(args, %{context: %{current_user: user}}) do
    resp =
      case Rooms.create_room(user, args) do
        {:ok, %{room: room, room_subscription: room_subscription}} ->
          %{success: true, room: room, room_subscription: room_subscription, errors: []}

        {:error, :room, changeset, _} ->
          %{success: false, room: nil, errors: format_errors(changeset)}

        # TODO: handle all possible failure modes comprehensively here?
        _ ->
          %{success: false, room: nil, errors: []}
      end

    {:ok, resp}
  end

  def update(args, %{context: %{current_user: user}}) do
    resp =
      case Rooms.get_room(user, args.id) do
        {:error, _} ->
          errors = [
            %{
              attribute: "base",
              message: dgettext("errors", "Room not found")
            }
          ]

          %{success: false, room: nil, errors: errors}

        {:ok, room} ->
          case Rooms.update_room(room, args) do
            {:ok, updated_room} ->
              %{success: true, room: updated_room, errors: []}

            {:error, changeset} ->
              %{success: false, room: room, errors: format_errors(changeset)}
          end
      end

    {:ok, resp}
  end

  def messages(room, args, _info) do
    Level.Connections.room_messages(room, args, %{})
  end

  def last_message(room, _args, _info) do
    Rooms.get_last_message(room)
  end

  def users(room, args, _info) do
    Level.Connections.room_users(room, args, %{})
  end
end
