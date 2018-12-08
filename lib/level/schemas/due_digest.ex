defmodule Level.Schemas.DueDigest do
  @moduledoc """
  The DueDigest schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "virtual: due digests" do
    field :digest_key, :string
    field :hour, :integer
    field :time_zone, :string

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
  end
end
