defmodule LevelWeb.RoomResolver do
  @moduledoc """
  GraphQL query resolution for rooms.
  """

  import LevelWeb.ResolverHelpers
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

  def messages(room, args, _info) do
    Level.Connections.room_messages(room, args, %{})
  end

  def users(room, args, _info) do
    Level.Connections.room_users(room, args, %{})
  end
end
