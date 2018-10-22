defmodule Level.Schemas.File do
  @moduledoc """
  The File schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.PostFile
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "files" do
    field :filename, :string
    field :content_type, :string
    field :size, :integer

    belongs_to :space, Space
    belongs_to :space_user, SpaceUser
    has_many :post_files, PostFile
    has_many :posts, through: [:post_files, :post]

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :space_user_id, :filename, :content_type, :size])
  end
end
