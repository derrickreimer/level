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
              %{success: true, room_message: message, errors: []}
            {:error, changeset} ->
              %{success: false, room_message: nil, errors: format_errors(changeset)}
          end

        {:ok, resp}
      error ->
        error
    end
  end
end
