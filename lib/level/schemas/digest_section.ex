defmodule Level.Schemas.DigestSection do
  @moduledoc """
  The DigestSection schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.Schemas.Digest
  alias Level.Schemas.DigestPost
  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "digest_sections" do
    field :title, :string
    field :summary, :string
    field :summary_html, :string
    field :link_text, :string
    field :link_url, :string
    field :rank, :integer

    belongs_to :space, Space
    belongs_to :digest, Digest
    has_many :digest_posts, DigestPost

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [
      :space_id,
      :digest_id,
      :title,
      :summary,
      :summary_html,
      :link_text,
      :link_url,
      :rank
    ])
    |> validate_required([:title])
  end
end
