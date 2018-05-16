defmodule Level.Groups.GroupBookmark do
  @moduledoc """
  The GroupBookmark schema.
  """

  use Ecto.Schema

  alias Level.Groups.Group
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "group_bookmarks" do
    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
    belongs_to :group, Group

    timestamps()
  end
end
