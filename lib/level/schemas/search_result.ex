defmodule Level.Schemas.SearchResult do
  @moduledoc """
  The SearchResult schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Post
  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key false
  @foreign_key_type :binary_id

  schema "post_searches" do
    field :searchable_id, :binary_id
    field :searchable_type, :string
    field :language, :string
    field :document, :string
    field :id, :string, virtual: true
    field :preview, :string, virtual: true
    field :rank, :float, virtual: true

    belongs_to :post, Post
    belongs_to :space, Space
  end
end
