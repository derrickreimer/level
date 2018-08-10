defmodule Level.Posts.UserMention do
  @moduledoc """
  The UserMention schema.
  """

  use Ecto.Schema

  alias Level.Posts.Post
  alias Level.Posts.Reply
  alias Level.Repo
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

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

  @doc false
  def insert_all(mentioned_ids, %Post{} = post) do
    now = DateTime.utc_now() |> DateTime.to_naive()

    params =
      Enum.map(mentioned_ids, fn mentioned_id ->
        %{
          space_id: post.space_id,
          post_id: post.id,
          reply_id: nil,
          mentioner_id: post.space_user_id,
          mentioned_id: mentioned_id,
          occurred_at: now,
          updated_at: now
        }
      end)

    __MODULE__
    |> Repo.insert_all(params)

    {:ok, mentioned_ids}
  end
end
