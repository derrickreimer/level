defmodule Level.Mentions.GroupedUserMention do
  @moduledoc """
  The abstract schema for grouped user mentions.
  """

  use Ecto.Schema

  alias Level.Posts.Post
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "abstract: grouped user_mentions" do
    field :reply_ids, {:array, :binary_id}
    field :mentioner_ids, {:array, :binary_id}
    field :last_occurred_at, :naive_datetime

    belongs_to :post, Post
    belongs_to :mentioned, SpaceUser, foreign_key: :mentioned_id

    # Un-aggregated fields used for querying but not populated
    field :occurred_at, :naive_datetime
  end
end
