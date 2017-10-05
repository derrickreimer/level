defmodule LevelWeb.RoomResolver do
  @moduledoc """
  GraphQL query resolution for rooms.
  """

  import LevelWeb.ResolverHelpers
  alias Level.Rooms

  def create(args, %{context: %{current_user: user}}) do
    resp =
      case Rooms.create_room(user, args) do
        {:ok, room} ->
          %{success: true, room: room, errors: []}

        {:error, changeset} ->
          %{success: false, room: nil, errors: format_errors(changeset)}
      end

    {:ok, resp}
  end
end
