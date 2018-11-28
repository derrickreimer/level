defmodule Level.Schemas.Nudge do
  @moduledoc """
  The Nudge schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "nudges" do
    field :minute, :integer

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :space_user_id, :minute])
    |> validate_required([:minute])
    |> validate_inclusion(:minute, 0..1439)
  end
end
