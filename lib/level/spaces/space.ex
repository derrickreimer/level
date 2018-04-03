defmodule Level.Spaces.Space do
  @moduledoc """
  A Space is the fundamental unit in Level. Think of a space like an "organization"
  or "company", just more concise and generically-named. All users must be
  related to a particular space, either as the the owner or some other role.

  The slug is the subdomain at which the space can be accessed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # @states ["ACTIVE", "DISABLED"]

  schema "spaces" do
    field :state, :string, read_after_writes: true
    field :name, :string
    field :slug, :string
    has_many :users, Level.Spaces.User

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

defimpl Phoenix.Param, for: Level.Spaces.Space do
  def to_param(%{slug: slug}) do
    slug
  end
end
