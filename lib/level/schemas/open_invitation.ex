defmodule Level.Schemas.OpenInvitation do
  @moduledoc """
  The OpenInvitation schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "open_invitations" do
    field :state, :string, read_after_writes: true
    field :token, :string
    belongs_to :space, Space

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:space_id, :token])
    |> generate_token()
  end

  defp generate_token(changeset) do
    token =
      16
      |> :crypto.strong_rand_bytes()
      |> Base.encode16()
      |> String.downcase()

    put_change(changeset, :token, token)
  end
end

defimpl Phoenix.Param, for: Level.Schemas.OpenInvitation do
  def to_param(%{token: token}) do
    token
  end
end
