defmodule Level.Groups.GroupMembership do
  @moduledoc """
  The GroupMembership schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Level.Spaces.Space
  alias Level.Spaces.User
  alias Level.Groups.Group

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_memberships" do
    belongs_to :space, Space
    belongs_to :user, User
    belongs_to :group, Group

    timestamps()
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:space_id, :user_id, :group_id])
    |> unique_constraint(
      :user,
      name: :group_memberships_user_id_group_id_index,
      message: dgettext("errors", "is already a member")
    )
  end
end
