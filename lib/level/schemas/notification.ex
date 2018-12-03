defmodule Level.Schemas.Notification do
  @moduledoc """
  The Notification schema.
  """

  use Ecto.Schema
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :state, :string, read_after_writes: true
    field :topic, :string
    field :event, :string
    field :data, :map

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser

    timestamps()
  end
end
