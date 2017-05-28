defmodule Bridge.Signup do
  @moduledoc """
  This is a virtual model that is bound to the new pod sign up form.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "signup" do
    field :pod_name, :string, vitrual: true
    field :email, :string, virtual: true
    field :password, :string, virtual: true
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pod_name, :email, :password])
  end
end
