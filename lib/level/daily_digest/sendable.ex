defmodule Level.DailyDigest.Sendable do
  @moduledoc false

  use Ecto.Schema

  alias Level.Schemas.User

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "space_users" do
    field :digest_key, :string
    field :hour, :integer
    belongs_to :user, User
  end
end
