defmodule Level.Schemas.PostLocator do
  @moduledoc """
  The PostLocator schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Post
  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_locators" do
    field :scope, :string
    field :topic, :string
    field :key, :string

    belongs_to :space, Space
    belongs_to :post, Post

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :post_id, :scope, :topic, :key])
    |> unique_constraint(:alias, name: :post_locators_space_id_scope_topic_key_index)
  end
end
