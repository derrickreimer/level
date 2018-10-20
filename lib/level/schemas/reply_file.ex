defmodule Level.Schemas.ReplyFile do
  @moduledoc """
  The ReplyFile schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Posts.Reply
  alias Level.Schemas.File
  alias Level.Spaces.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reply_files" do
    belongs_to :space, Space
    belongs_to :reply, Reply
    belongs_to :file, File

    timestamps(updated_at: false)
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :reply_id, :file_id])
  end
end
