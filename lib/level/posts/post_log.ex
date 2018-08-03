defmodule Level.Posts.PostLog do
  @moduledoc """
  The PostLog schema.
  """

  use Ecto.Schema

  alias Level.Groups.Group
  alias Level.Posts.Post
  alias Level.Posts.Reply
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_log" do
    field :event, :string
    field :occurred_at, :naive_datetime

    belongs_to :space, Space
    belongs_to :group, Group
    belongs_to :post, Post
    belongs_to :actor, SpaceUser, foreign_key: :actor_id
    belongs_to :reply, Reply
  end
end
