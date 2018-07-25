defmodule Level.Spaces.Space do
  @moduledoc """
  The Space schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "spaces" do
    field :state, :string, read_after_writes: true
    field :name, :string
    field :slug, :string
    field :avatar, :string
    has_many :space_users, SpaceUser

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug, name: :spaces_lower_slug_index)
  end

  @doc """
  The regex format for a slug.
  """
  def slug_format do
    ~r/^(?>[a-z0-9][a-z0-9-]*[a-z0-9])$/
  end
end

defimpl Phoenix.Param, for: Level.Spaces.Space do
  def to_param(%{slug: slug}) do
    slug
  end
end
