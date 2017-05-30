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
  The regex format for a slug.
  """
  def slug_format do
    ~r/^(?>[a-z0-9][a-z0-9-]*[a-z0-9])$/
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :slug])
    |> put_change(:state, 0) # TODO: implement real states
    |> unique_constraint(:slug)
  end

  @doc """
  Builds a changeset for signup based on the `struct` and `params`.
  This method gets used within the Signup.multi function.
  """
  def signup_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :slug])
    |> put_change(:state, 0) # TODO: implement real states
  end
end
