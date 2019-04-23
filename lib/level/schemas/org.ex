defmodule Level.Schemas.Org do
  @moduledoc """
  The Org schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Level.Schemas.Space

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "orgs" do
    field :subscription_state, :string, read_after_writes: true
    field :name, :string
    field :stripe_customer_id, :string
    field :stripe_subscription_id, :string
    field :seat_quantity, :integer

    has_many :spaces, Space

    timestamps()
  end

  @doc false
  def create_changeset(%__MODULE__{} = org, attrs) do
    org
    |> cast(attrs, [
      :subscription_state,
      :name,
      :stripe_customer_id,
      :stripe_subscription_id,
      :seat_quantity
    ])
    |> validate_required([:name, :seat_quantity])
  end
end
