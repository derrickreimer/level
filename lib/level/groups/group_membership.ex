defmodule Level.Groups.GroupMembership do
  @moduledoc """
  The GroupMembership schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_memberships" do
    belongs_to :space, Space
    belongs_to :user, User
    belongs_to :group, Group

    timestamps()
  end
end
