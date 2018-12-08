defmodule Level.Schemas.DueNudge do
  @moduledoc """
  The DueNudge schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "virtual: due nudges" do
    field :digest_key, :string
    field :minute, :integer
    field :current_minute, :integer
    field :time_zone, :string

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
  end
end
