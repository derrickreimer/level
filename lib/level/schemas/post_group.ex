defmodule Level.Schemas.PostGroup do
  @moduledoc """
  The PostGroup schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Group
  alias Level.Schemas.Post
  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_groups" do
    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :group, Group

    timestamps()
  end
end
