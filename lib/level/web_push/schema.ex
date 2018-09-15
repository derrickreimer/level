defmodule Level.WebPush.Schema do
  @moduledoc """
  The subscription schema.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "push_subscriptions" do
    field :user_id, :binary_id
    field :digest, :string
    field :data, :string

    timestamps()
  end
end
