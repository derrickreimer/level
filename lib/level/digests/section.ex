defmodule Level.Digests.Section do
  @moduledoc """
  A section in a digest.
  """

  alias Level.Schemas.Post

  defstruct [:title, :summary, :summary_html, :link_text, :link_url, :posts]

  @type t :: %__MODULE__{
          title: String.t(),
          summary: String.t(),
          summary_html: String.t(),
          link_text: String.t(),
          link_url: String.t(),
          posts: [Post.t()]
        }
end
