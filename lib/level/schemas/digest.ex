defmodule Level.Schemas.Digest do
  @moduledoc """
  The Digest schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.OlsonTimeZone
  alias Level.Schemas.DigestSection
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "digests" do
    field :key, :string
    field :title, :string
    field :subject, :string
    field :to_email, :string
    field :start_at, :naive_datetime
    field :end_at, :naive_datetime
    field :time_zone, :string

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
    has_many :digest_sections, DigestSection

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :space_id,
      :space_user_id,
      :key,
      :title,
      :subject,
      :to_email,
      :start_at,
      :end_at,
      :time_zone
    ])
    |> OlsonTimeZone.validate(:time_zone)
  end
end
