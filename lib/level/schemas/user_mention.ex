defmodule Level.Schemas.UserMention do
  @moduledoc """
  The UserMention schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Post
  alias Level.Schemas.Reply
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_mentions" do
    field :dismissed_at, :naive_datetime

    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :reply, Reply
    belongs_to :mentioner, SpaceUser, foreign_key: :mentioner_id
    belongs_to :mentioned, SpaceUser, foreign_key: :mentioned_id

    timestamps(inserted_at: :occurred_at)
  end
end
