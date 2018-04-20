defmodule Level.Spaces.Member do
  @moduledoc """
  The Space Member context.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "space_members" do
    field :state, :string, read_after_writes: true
    field :role, :string, read_after_writes: true
    belongs_to :space, Level.Spaces.Space
    belongs_to :user, Level.Users.User

    # Holds the group name when loaded via a join
    field :name, :string, virtual: true

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:user_id, :space_id, :role])
    |> validate_required([:role])

    # TODO: add unique validation
  end
end
