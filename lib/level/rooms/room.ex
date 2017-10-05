defmodule Level.Rooms.Room do
  @moduledoc """
  The Ecto schema for the rooms table.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :state, :string, read_after_writes: true # room_state
    field :name, :string
    field :description, :string, read_after_writes: true
    field :is_private, :boolean, read_after_writes: true
    belongs_to :space, Level.Spaces.Space
    belongs_to :creator, Level.Spaces.User

    timestamps()
  end

  @doc """
  Builds a changeset for creating a room.
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:space_id, :creator_id, :name, :description, :is_private])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :rooms_unique_ci_name)
  end
end
