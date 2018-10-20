defmodule Level.Schemas.Post do
  @moduledoc """
  The Post schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Group
  alias Level.Schemas.PostFile
  alias Level.Schemas.PostGroup
  alias Level.Schemas.PostLog
  alias Level.Schemas.PostUser
  alias Level.Schemas.Reply
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.UserMention

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "posts" do
    field :state, :string, read_after_writes: true
    field :body, :string
    field :language, :string

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
    belongs_to :space_bot, SpaceBot

    many_to_many :groups, Group, join_through: PostGroup
    has_many :replies, Reply
    has_many :user_mentions, UserMention
    has_many :post_logs, PostLog
    has_many :post_users, PostUser
    has_many :post_files, PostFile
    has_many :files, through: [:post_files, :file]

    # Used for paginating
    field :last_pinged_at, :naive_datetime, virtual: true
    field :last_activity_at, :naive_datetime, virtual: true

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :space_user_id, :body])
    |> validate_required([:body])
  end

  @doc false
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
