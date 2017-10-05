defmodule Level.Rooms.RoomSubscription do
  @moduledoc """
  The Ecto schema for the room subscriptions table.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "room_subscriptions" do
    belongs_to :space, Level.Spaces.Space
    belongs_to :user, Level.Spaces.User
    belongs_to :room, Level.Rooms.Room

    timestamps()
  end

  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:space_id, :user_id, :room_id])
  end
end
