defmodule Level.Posts.Reply do
  @moduledoc """
  The Reply schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Posts.Post
  alias Level.ReplyFile
  alias Level.SpaceBot
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "replies" do
    field :body, :string
    field :language, :string

    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :author, SpaceUser, foreign_key: :space_user_id
    belongs_to :space_bot, SpaceBot

    has_many :reply_files, ReplyFile
    has_many :files, through: [:reply_files, :file]

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :space_user_id, :post_id, :body])
    |> validate_required([:body])
  end

  @doc false
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
