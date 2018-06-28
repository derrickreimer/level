defmodule Level.Posts.Post do
  @moduledoc """
  The Post schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Groups.Group
  alias Level.Posts.PostGroup
  alias Level.Posts.Reply
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "posts" do
    field :state, :string, read_after_writes: true
    field :body, :string

    belongs_to :space, Space
    belongs_to :author, SpaceUser, foreign_key: :space_user_id
    many_to_many :groups, Group, join_through: PostGroup
    has_many :replies, Reply

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :space_user_id, :body])
    |> validate_required([:body])
  end
end
