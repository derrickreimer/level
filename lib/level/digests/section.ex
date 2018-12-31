defmodule Level.Digests.Section do
  @moduledoc """
  A section in a digest.
  """

  alias Level.Digests.Options
  alias Level.Digests.Post
  alias Level.Schemas
  alias Level.Schemas.SpaceUser

  defstruct [:title, :summary, :summary_html, :link_text, :link_url, :posts]

  @type t :: %__MODULE__{
          title: String.t(),
          summary: String.t(),
          summary_html: String.t(),
          link_text: String.t(),
          link_url: String.t(),
          posts: [Post.t()]
        }

  @doc """
  Builds a section.
  """
  @callback build(Schemas.Digest.t(), SpaceUser.t(), Options.t()) :: {:ok, t()} | :skip

  @doc """
  Determines whether the section has any data to show.
  """
  @callback has_data?(SpaceUser.t(), Options.t()) :: boolean()
end
