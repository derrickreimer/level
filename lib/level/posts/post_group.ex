defmodule Level.Posts.PostGroup do
  @moduledoc """
  The PostGroup schema.
  """

  use Ecto.Schema

  alias Level.Groups.Group
  alias Level.Posts.Post
  alias Level.Spaces.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_groups" do
    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :group, Post

    timestamps()
  end
end
