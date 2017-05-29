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
  Builds a changeset for signup based on the `struct` and `params`.
  This method gets used within the Signup.multi function.
  """
  def signup_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :slug])
    |> put_change(:state, 0) # TODO: implement real states
  end
end
