defmodule Level.Schemas.GroupUser do
  @moduledoc """
  The GroupUser schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Level.Schemas.Group
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_users" do
    field :state, :string, read_after_writes: true
    field :role, :string, read_after_writes: true
    field :access, :string, read_after_writes: true

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
    belongs_to :group, Group
    has_one :user, through: [:space_user, :user]

    # Holds the group name when loaded via a join
    field :name, :string, virtual: true

    # Holds the user's last name when loaded via a join
    field :last_name, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:space_id, :space_user_id, :group_id, :state])
    |> unique_constraint(
      :user,
      name: :group_users_space_user_id_group_id_index,
      message: dgettext("errors", "is already a member")
    )
  end
end
