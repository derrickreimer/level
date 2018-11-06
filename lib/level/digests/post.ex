defmodule Level.Digests.Post do
  @moduledoc """
  A post in a digest.
  """

  alias Level.Digests.Reply
  alias Level.Schemas.Group
  alias Level.Schemas.SpaceUser

  defstruct [:id, :state, :body, :author, :groups, :replies, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          state: String.t(),
          body: String.t(),
          author: SpaceUser.t(),
          groups: [Group.t()],
          replies: [Reply.t()],
          inserted_at: NaiveDateTime.t()
        }
end
