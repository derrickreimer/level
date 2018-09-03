defmodule Level.Posts.PostUserLog do
  @moduledoc """
  The PostUserLog schema.
  """

  use Ecto.Schema

  alias Level.Posts.Post
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_user_log" do
    field :event, :string

    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :space_user, SpaceUser

    timestamps(inserted_at: :occurred_at, updated_at: false)
  end
end
