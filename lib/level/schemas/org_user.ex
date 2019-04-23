defmodule Level.Schemas.OrgUser do
  @moduledoc """
  The OrgUser schema.
  """

  use Ecto.Schema

  alias Level.Schemas.Org
  alias Level.Schemas.User

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "org_users" do
    field :state, :string, read_after_writes: true
    field :role, :string, default: "OWNER"

    belongs_to :org, Org
    belongs_to :user, User

    timestamps()
  end
end
