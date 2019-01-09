defmodule Level.Digests.Reply do
  @moduledoc """
  Represents a reply with some additional metadata for display in digests.
  """

  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.Reply

  @enforce_keys [:id, :body, :author, :posted_at, :has_viewed]
  defstruct [:id, :body, :author, :posted_at, :has_viewed]

  @type t :: %__MODULE__{
          id: String.t(),
          body: String.t(),
          author: SpaceUser.t() | SpaceBot.t(),
          posted_at: NaiveDateTime.t(),
          has_viewed: boolean()
        }

  def build(%SpaceUser{} = viewer, %Reply{} = record) do
    record =
      record
      |> Repo.preload(:space_user)
      |> Repo.preload(:space_bot)

    %__MODULE__{
      id: record.id,
      body: record.body,
      author: record.space_bot || record.space_user,
      posted_at: record.inserted_at,
      has_viewed: Posts.viewed_reply?(record, viewer)
    }
  end
end
