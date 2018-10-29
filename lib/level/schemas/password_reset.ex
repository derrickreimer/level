defmodule Level.Schemas.PasswordReset do
  @moduledoc """
  The PasswordReset schema.
  """

  use Ecto.Schema

  alias Level.Schemas.User

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "password_resets" do
    field :expires_at, :naive_datetime

    belongs_to :user, User

    timestamps()
  end
end
