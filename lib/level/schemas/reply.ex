defmodule Level.Schemas.Reply do
  @moduledoc """
  The Reply schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Post
  alias Level.Schemas.ReplyFile
  alias Level.Schemas.ReplyReaction
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "replies" do
    field :body, :string
    field :language, :string

    belongs_to :space, Space
    belongs_to :post, Post

    belongs_to :space_user, SpaceUser
    belongs_to :space_bot, SpaceBot

    has_many :reply_files, ReplyFile
    has_many :files, through: [:reply_files, :file]
    has_many :reply_reactions, ReplyReaction

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
