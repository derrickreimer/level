defmodule Level.Connections.RoomUsers do
  @moduledoc false

  alias Level.Rooms.RoomSubscription
  alias Level.Spaces.User
  import Ecto.Query

  @default_args %{
    first: nil,
    last: nil,
    before: nil,
    after: nil,
    order_by: %{
      field: :last_name,
      direction: :asc
    }
  }

  @doc """
  Execute a paginated query for users subscribed to a given room.
  """
  def get(room, args, _context) do
    case validate_args(args) do
      {:ok, args} ->
        base_query =
          from u in User,
            join: s in RoomSubscription,
            on: s.user_id == u.id and s.room_id == ^room.id

        Level.Pagination.fetch_result(Level.Repo, base_query, args)

      error ->
        error
    end
  end

  defp validate_args(args) do
    # TODO: return {:error, message} if args are not valid
    {:ok, Map.merge(@default_args, args)}
  end
end
