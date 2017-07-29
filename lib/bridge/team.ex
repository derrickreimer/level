defmodule Bridge.Team do
  @moduledoc """
  A Team is the fundamental unit in Bridge. Think of a team like an "organization"
  or "company", just more concise and generically-named. All users must be
  related to a particular team, either as the the owner or some other role.

  The slug is the subdomain at which the team can be accessed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :state, :string
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
    |> unique_constraint(:slug)
  end

  @doc """
  Builds a changeset for signup based on the `struct` and `params`.
  This method gets used within the Signup.multi function.
  """
  def signup_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :slug])
  end
end

defimpl Phoenix.Param, for: Bridge.Team do
  def to_param(%{slug: slug}) do
    slug
  end
end
