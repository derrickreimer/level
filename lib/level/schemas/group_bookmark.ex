defmodule Level.Schemas.GroupBookmark do
  @moduledoc """
  The GroupBookmark schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Group
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

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
