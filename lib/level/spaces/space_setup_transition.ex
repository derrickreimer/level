defmodule Level.Spaces.SpaceSetupTransition do
  @moduledoc """
  The SpaceSetupTransition schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "space_setup_transitions" do
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
    |> unique_constraint(:state, name: :space_setup_transitions_space_id_state_index)
  end
end
