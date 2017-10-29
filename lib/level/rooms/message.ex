defmodule Level.Rooms.Message do
  @moduledoc """
  The Ecto schema for the room messages table.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "room_messages" do
    field :body, :string

    belongs_to :space, Level.Spaces.Space
    belongs_to :user, Level.Spaces.User
    belongs_to :room, Level.Rooms.Room

    timestamps()
  end

  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:space_id, :user_id, :room_id, :body])
    |> validate_required([:body])
    |> validate_length(:body, min: 1, max: 1000) # TODO: think about max length
  end
end
