defmodule Level.Users.PushSubscription do
  @moduledoc """
  The PushSubscription schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Level.Users.User

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "push_subscriptions" do
    field :digest, :string
    field :data, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:user_id, :data])
    |> validate_required([:data])
    |> put_digest()
  end

  defp put_digest(%Changeset{valid?: true, changes: %{data: data}} = changeset) do
    put_change(changeset, :digest, compute_digest(data))
  end

  defp put_digest(changeset), do: changeset

  defp compute_digest(data) do
    :sha256
    |> :crypto.hash(data)
    |> Base.encode16()
  end
end
