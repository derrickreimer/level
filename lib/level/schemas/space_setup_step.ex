defmodule Level.Schemas.SpaceSetupStep do
  @moduledoc """
  The SpaceSetupStep schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "space_setup_steps" do
    field :state, :string, read_after_writes: true
    field :is_skipped, :boolean
    belongs_to :space, Space
    belongs_to :space_user, SpaceUser

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_user_id, :space_id, :state, :is_skipped])
    |> validate_required([:state, :is_skipped])
    |> unique_constraint(:state, name: :space_setup_steps_space_id_state_index)
  end
end
