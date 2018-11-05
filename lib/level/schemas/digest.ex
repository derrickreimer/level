defmodule Level.Schemas.Digest do
  @moduledoc """
  The Digest schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "digests" do
    field :title, :string
    field :start_at, :naive_datetime
    field :end_at, :naive_datetime

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :space_user_id, :title, :start_at, :end_at])
    |> validate_required([:title, :start_at, :end_at])
  end
end
