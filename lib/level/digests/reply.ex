defmodule Level.Digests.Reply do
  @moduledoc """
  A reply to a post in a digest.
  """

  alias Level.Schemas.SpaceUser

  defstruct [:id, :body, :author, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          body: String.t(),
          author: SpaceUser.t(),
          inserted_at: NaiveDateTime.t()
        }
end
