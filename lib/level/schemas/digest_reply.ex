defmodule Level.Schemas.DigestReply do
  @moduledoc """
  The DigestReply schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.Schemas.Digest
  alias Level.Schemas.DigestPost
  alias Level.Schemas.Reply
  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "digest_replies" do
    belongs_to :space, Space
    belongs_to :digest, Digest
    belongs_to :digest_post, DigestPost
    belongs_to :reply, Reply

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :digest_id, :digest_post_id, :reply_id])
  end
end
