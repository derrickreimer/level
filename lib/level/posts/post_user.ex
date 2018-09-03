defmodule Level.Posts.PostUser do
  @moduledoc """
  The PostUser schema.
  """

  use Ecto.Schema

  alias Level.Posts.Post
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_users" do
    field :subscription_state, :string, read_after_writes: true
    field :inbox_state, :string, read_after_writes: true

    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :space_user, SpaceUser

    timestamps()
  end
end
