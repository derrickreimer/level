defmodule Level.Schemas.DigestPost do
  @moduledoc """
  The DigestPost schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.Schemas.Digest
  alias Level.Schemas.DigestSection
  alias Level.Schemas.Post
  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "digest_posts" do
    field :rank, :integer

    belongs_to :space, Space
    belongs_to :digest, Digest
    belongs_to :digest_section, DigestSection
    belongs_to :post, Post

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :digest_id, :digest_section_id, :post_id, :rank])
    |> validate_required([:title])
  end
end
