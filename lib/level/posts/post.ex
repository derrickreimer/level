defmodule Level.Posts.Post do
  @moduledoc """
  The Post schema.
  """

  use Ecto.Schema

  alias Level.Spaces.Space
  alias Level.Spaces.User

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "posts" do
    field :state, :string, read_after_writes: true
    field :body, :string

    belongs_to :space, Space
    belongs_to :user, User

    timestamps()
  end
end
