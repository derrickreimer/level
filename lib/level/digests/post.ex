defmodule Level.Digests.Post do
  @moduledoc """
  Represents a post, including a preview of the replies, for display in a digest.
  """

  import Ecto.Query

  alias Level.Digests.Reply
  alias Level.Repo
  alias Level.Schemas.Group
  alias Level.Schemas.Post
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  @enforce_keys [
    :id,
    :state,
    :body,
    :author,
    :groups,
    :recent_replies,
    :posted_at,
    :display_name,
    :initials,
    :avatar_color
  ]

  defstruct [
    :id,
    :state,
    :body,
    :author,
    :groups,
    :recent_replies,
    :posted_at,
    :display_name,
    :initials,
    :avatar_color
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          state: String.t(),
          body: String.t(),
          author: SpaceUser.t() | SpaceBot.t(),
          groups: [Group.t()],
          recent_replies: [Reply.t()],
          posted_at: NaiveDateTime.t(),
          display_name: String.t() | nil,
          initials: String.t() | nil,
          avatar_color: String.t() | nil
        }

  def build(%SpaceUser{} = viewer, %Post{} = record) do
    record =
      record
      |> Repo.preload(:space_user)
      |> Repo.preload(:space_bot)
      |> Repo.preload(:groups)

    recent_replies =
      record
      |> Ecto.assoc(:replies)
      |> preload(:space_user)
      |> preload(:space_bot)
      |> order_by(desc: :inserted_at)
      |> limit(3)
      |> Repo.all()
      |> Enum.reverse()
      |> Enum.map(fn reply -> Reply.build(viewer, reply) end)

    %__MODULE__{
      id: record.id,
      state: record.state,
      body: record.body,
      author: record.space_bot || record.space_user,
      groups: record.groups,
      recent_replies: recent_replies,
      posted_at: record.inserted_at,
      display_name: record.display_name,
      initials: record.initials,
      avatar_color: record.avatar_color
    }
  end
end
