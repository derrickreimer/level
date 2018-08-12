defmodule Level.Posts.PostView do
  @moduledoc """
  The PostView schema.
  """

  use Ecto.Schema

  alias Level.Posts.Post
  alias Level.Posts.Reply
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_views" do
    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :space_user, SpaceUser
    belongs_to :last_viewed_reply, Reply, foreign_key: :last_viewed_reply_id

    timestamps(inserted_at: :occurred_at, updated_at: false)
  end
end
