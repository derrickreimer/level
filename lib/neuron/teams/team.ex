defmodule Neuron.Teams.Team do
  @moduledoc """
  A Team is the fundamental unit in Neuron. Think of a team like an "organization"
  or "company", just more concise and generically-named. All users must be
  related to a particular team, either as the the owner or some other role.

  The slug is the subdomain at which the team can be accessed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  # @states ["ACTIVE", "DISABLED"]

  schema "teams" do
    field :state, :string, read_after_writes: true # team_state
    field :name, :string
    field :slug, :string
    has_many :users, Neuron.Teams.User

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

defimpl Phoenix.Param, for: Neuron.Teams.Team do
  def to_param(%{slug: slug}) do
    slug
  end
end
