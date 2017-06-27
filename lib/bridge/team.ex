defmodule Bridge.Team do
  @moduledoc """
  A Team is the fundamental unit in Bridge. Think of a team like an "organization"
  or "company", just more concise and generically-named. All users must be
  related to a particular team, either as the the owner or some other role.

  The slug is the subdomain at which the team can be accessed.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Bridge.Repo

  schema "teams" do
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
    |> put_change(:state, 0)
    |> unique_constraint(:slug)
  end

  @doc """
  Builds a changeset for signup based on the `struct` and `params`.
  This method gets used within the Signup.multi function.
  """
  def signup_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :slug])
    |> put_change(:state, 0)
  end

  @doc """
  Determines if a given slug is a valid format and not yet taken.
  """
  def slug_valid?(slug) do
    message = cond do
      !(slug =~ slug_format()) ->
        "must be lowercase and alphanumeric"
      Repo.one(__MODULE__, slug: slug) != nil ->
        "is already taken"
      true ->
        nil
    end

    if message do
      {:error, %{message: message}}
    else
      {:ok}
    end
  end
end

defimpl Phoenix.Param, for: Bridge.Team do
  def to_param(%{slug: slug}) do
    slug
  end
end
