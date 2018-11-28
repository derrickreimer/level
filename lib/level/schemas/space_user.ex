defmodule Level.Schemas.SpaceUser do
  @moduledoc """
  The SpaceUser context.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Level.Gettext

  alias Level.Handles
  alias Level.Schemas.File
  alias Level.Schemas.Nudge
  alias Level.Schemas.PostUser
  alias Level.Schemas.Space
  alias Level.Schemas.User

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "space_users" do
    field :state, :string, read_after_writes: true
    field :role, :string, read_after_writes: true
    field :is_digest_enabled, :boolean, read_after_writes: true
    field :first_name, :string
    field :last_name, :string
    field :handle, :string
    field :avatar, :string

    belongs_to :space, Space
    belongs_to :user, User

    has_many :post_users, PostUser
    has_many :files, File
    has_many :nudges, Nudge

    # Fields from the joined space record
    field :space_name, :string, virtual: true

    timestamps()
  end

  @doc """
  Generates a display name for a space user.
  """
  def display_name(%__MODULE__{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :user_id,
      :space_id,
      :role,
      :first_name,
      :last_name,
      :handle,
      :avatar,
      :is_digest_enabled
    ])
    |> validate_required([:role, :first_name, :last_name, :handle])
    |> Handles.validate_format(:handle)
    |> unique_constraint(:handle,
      name: :space_users_space_id_lower_handle_index,
      message: dgettext("errors", "is already taken")
    )
  end

  @doc false
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:role, :first_name, :last_name, :handle, :avatar, :is_digest_enabled])
    |> validate_required([:role, :first_name, :last_name, :handle])
    |> Handles.validate_format(:handle)
    |> unique_constraint(:handle,
      name: :space_users_space_id_lower_handle_index,
      message: dgettext("errors", "is already taken")
    )
  end
end
