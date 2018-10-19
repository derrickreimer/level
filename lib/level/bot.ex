defmodule Level.Bot do
  @moduledoc """
  The Bot schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Level.Handles

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bots" do
    field :state, :string, read_after_writes: true
    field :handle, :string
    field :display_name, :string
    field :avatar, :string

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
