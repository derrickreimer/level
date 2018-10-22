defmodule Level.Schemas.PostVersion do
  @moduledoc """
  The PostVersion schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Post
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_versions" do
    field :body, :string

    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :author, SpaceUser

    timestamps(updated_at: false)
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :author_id, :post_id, :body])
    |> validate_required([:body])
  end
end
