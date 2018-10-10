defmodule Level.Spaces.SpaceUser do
  @moduledoc """
  The SpaceUser context.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Level.Gettext

  alias Level.Posts.PostUser
  alias Level.Spaces.Space
  alias Level.Users
  alias Level.Users.User
  alias Level.Upload

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "space_users" do
    field :state, :string, read_after_writes: true
    field :role, :string, read_after_writes: true
    field :first_name, :string
    field :last_name, :string
    field :handle, :string
    field :avatar, :string
    belongs_to :space, Space
    belongs_to :user, User
    has_many :post_users, PostUser
    has_many :uploads, Upload

    # Fields from the joined space record
    field :space_name, :string, virtual: true

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:user_id, :space_id, :role, :first_name, :last_name, :handle, :avatar])
    |> validate_required([:role, :first_name, :last_name, :handle])
    |> validate_format(
      :handle,
      Users.handle_format(),
      message: dgettext("errors", "must contain letters, numbers, and dashes only")
    )
    |> unique_constraint(:handle,
      name: :space_users_space_id_lower_handle_index,
      message: dgettext("errors", "is already taken")
    )
  end

  @doc false
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:role, :first_name, :last_name, :handle, :avatar])
    |> validate_required([:role, :first_name, :last_name, :handle])
    |> validate_format(
      :handle,
      Users.handle_format(),
      message: dgettext("errors", "must contain letters, numbers, and dashes only")
    )
    |> unique_constraint(:handle,
      name: :space_users_space_id_lower_handle_index,
      message: dgettext("errors", "is already taken")
    )
  end
end
