defmodule Level.Schemas.Space do
  @moduledoc """
  The Space schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Level.Schemas.Group
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "spaces" do
    field :state, :string, read_after_writes: true
    field :is_demo, :boolean, read_after_writes: true
    field :name, :string, default: ""
    field :slug, :string, default: ""
    field :avatar, :string
    field :postbot_key, :string

    has_many :space_users, SpaceUser
    has_many :groups, Group

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:name, :slug, :avatar, :is_demo])
    |> validate_required([:name, :slug])
    |> validate_format(
      :slug,
      slug_format(),
      message: dgettext("errors", "contains invalid characters")
    )
    |> set_postbot_key()
    |> unique_constraint(:slug, name: :spaces_lower_slug_index)
  end

  @doc false
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:name, :slug, :avatar])
    |> validate_required([:name, :slug])
    |> validate_format(
      :slug,
      slug_format(),
      message: dgettext("errors", "contains invalid characters")
    )
    |> unique_constraint(:slug, name: :spaces_lower_slug_index)
  end

  @doc """
  The regex format for a slug.
  """
  def slug_format do
    ~r/^(?>[A-Za-z][A-Za-z0-9-\.]*[A-Za-z0-9])$/
  end

  defp set_postbot_key(changeset) do
    key =
      16
      |> :crypto.strong_rand_bytes()
      |> Base.encode16()
      |> String.downcase()

    changeset
    |> Ecto.Changeset.change(postbot_key: key)
  end
end

defimpl Phoenix.Param, for: Level.Schemas.Space do
  def to_param(%{slug: slug}) do
    slug
  end
end
