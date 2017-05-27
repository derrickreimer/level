defmodule Bridge.Pod do
  @moduledoc """
  A Pod is the fundamental unit in Bridge. Think of a pod like an "organization"
  or "company", just more concise and generically-named. All users must be
  related to a particular pod, either as the the owner or some other role.

  The slug is the subdomain at which the pod can be accessed.
  """

  use Bridge.Web, :model

  schema "pods" do
    field :name, :string
    field :state, :integer
    field :slug, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :state, :slug])
    |> validate_required([:name, :state, :slug])
  end
end
