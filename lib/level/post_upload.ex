defmodule Level.PostUpload do
  @moduledoc """
  The PostUpload schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Posts.Post
  alias Level.Spaces.Space
  alias Level.Upload

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_uploads" do
    belongs_to :space, Space
    belongs_to :post, Post
    belongs_to :upload, Upload

    timestamps(updated_at: false)
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :post_id, :upload_id])
  end
end
