defmodule Level.Groups.Member do
  @moduledoc """
  The Group Member schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Level.Groups.Group
  alias Level.Spaces.Member
  alias Level.Spaces.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_members" do
    belongs_to :space, Space
    belongs_to :space_member, Member
    belongs_to :group, Group

    # Holds the group name when loaded via a join
    field :name, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:space_id, :space_member_id, :group_id])
    |> unique_constraint(
      :user,
      name: :group_members_space_member_id_group_id_index,
      message: dgettext("errors", "is already a member")
    )
  end
end
