defmodule Bridge.User do
  @moduledoc """
  A User always belongs to a pod and has a specific role in the pod.
  """

  use Bridge.Web, :model

  schema "users" do
    field :state, :integer
    field :role, :integer
    field :email, :string
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :password_hash, :string
    belongs_to :pod, Bridge.Pod

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:state, :role, :email, :username, :first_name, :last_name, :time_zone, :password_hash])
    |> validate_required([:state, :role, :email, :username, :first_name, :last_name, :time_zone, :password_hash])
  end
end
