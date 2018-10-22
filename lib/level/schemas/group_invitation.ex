defmodule Level.Schemas.GroupInvitation do
  @moduledoc """
  The GroupInvitation schema.
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

  schema "group_invitations" do
    field :state, :string, read_after_writes: true

    belongs_to :space, Space
    belongs_to :group, Group
    belongs_to :invitor, SpaceUser
    belongs_to :invitee, SpaceUser

    timestamps()
  end

  @doc false
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:space_id, :group_id, :invitor_id, :invitee_id])
    |> unique_constraint(
      :user,
      name: :group_invitations_unique,
      message: dgettext("errors", "has already been invited")
    )
  end
end
