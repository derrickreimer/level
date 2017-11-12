defmodule LevelWeb.RoomResolver do
  @moduledoc """
  GraphQL query resolution for rooms.
  """

  import LevelWeb.ResolverHelpers
  alias Level.Rooms

  def create(args, %{context: %{current_user: user}}) do
    resp =
      case Rooms.create_room(user, args) do
        {:ok, %{room: room, room_subscription: _}} ->
          %{success: true, room: room, errors: []}

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
end
