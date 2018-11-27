defmodule Level.Schemas.Tutorial do
  @moduledoc """
  The Tutorial schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tutorials" do
    field :key, :string
    field :current_step, :integer, read_after_writes: true
    field :is_complete, :boolean, default: false, read_after_writes: true

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser

    timestamps()
  end
end
