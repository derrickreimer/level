defmodule Level.Schemas.ReplyReaction do
  @moduledoc """
  The ReplyReaction schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Post
  alias Level.Schemas.Reply
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reply_reactions" do
    field :value, :string, read_after_writes: true

    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :reply, Reply
    belongs_to :space_user, SpaceUser

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :space_user_id, :post_id, :reply_id, :value])
    |> validate_required([:value])
    |> validate_length(:value, min: 1, max: 16)
  end
end
