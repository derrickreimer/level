defmodule Bridge.User do
  @moduledoc """
  A User always belongs to a team and has a specific role in the team.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Bridge.Web.Gettext

  alias Comeonin.Bcrypt
  alias Ecto.Changeset

  schema "users" do
    field :state, :string # user_state
    field :role, :string # user_role
    field :email, :string
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    belongs_to :team, Bridge.Team

    timestamps()
  end

  @doc """
  The regex format for a username.
  """
  def username_format do
    ~r/^(?>[a-z][a-z0-9-\.]*[a-z0-9])$/
  end

  @doc """
  The regex format for an email address.
  Borrowed from http://www.regular-expressions.info/email.html
  """
  def email_format do
    ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
  end

  @doc """
  Builds a changeset for signup based on the `struct` and `params`.
  This method gets used within the Signup.multi function.
  """
  def signup_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:team_id, :role, :email, :username, :time_zone, :password])
    |> validate_user_params()
    |> put_default_time_zone
    |> put_pass_hash
  end

  @doc """
  Applies user attribute validations to a changeset.
  """
  def validate_user_params(changeset) do
    changeset
    |> validate_required([:username, :email, :password])
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:username, min: 3, max: 20)
    |> validate_length(:password, min: 6)
    |> validate_format(:username, username_format(), message: dgettext("errors", "must be lowercase and alphanumeric"))
    |> validate_format(:email, email_format(), message: dgettext("errors", "is invalid"))
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end

  defp put_default_time_zone(changeset) do
    case changeset do
      %Changeset{changes: %{time_zone: ""}} ->
        put_change(changeset, :time_zone, "UTC")
      %Changeset{changes: %{time_zone: _}} ->
        changeset
      _ ->
        put_change(changeset, :time_zone, "UTC")
    end
  end
end
