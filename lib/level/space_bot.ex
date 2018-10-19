defmodule Level.SpaceBot do
  @moduledoc """
  The SpaceBot schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Level.Bot
  alias Level.Handles
  alias Level.Spaces.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "space_bots" do
    field :state, :string, read_after_writes: true
    field :handle, :string
    field :display_name, :string
    field :avatar, :string

    belongs_to :space, Space
    belongs_to :bot, Bot

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:display_name, :handle])
    |> validate_required([:display_name, :handle])
    |> Handles.validate_format(:handle)
    |> unique_constraint(:handle,
      name: :bots_lower_handle_index,
      message: dgettext("errors", "is already taken")
    )
  end
end
