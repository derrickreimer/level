defmodule Level.Spaces.User do
  @moduledoc """
  A User always belongs to a space and has a specific role in the space.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Comeonin.Bcrypt
  alias Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # @states ["ACTIVE", "DISABLED"]
  # @roles ["OWNER", "ADMIN", "MEMBER"]

  schema "users" do
    field :state, :string, read_after_writes: true
    field :role, :string, read_after_writes: true
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :session_salt, :string
    belongs_to :space, Level.Spaces.Space

    timestamps()
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
    |> cast(params, [
      :space_id,
      :role,
      :email,
      :first_name,
      :last_name,
      :time_zone,
      :password
    ])
    |> validate_user_params()
    |> put_default_time_zone
    |> put_pass_hash
    |> put_change(:session_salt, generate_salt())
  end

  @doc """
  Applies user attribute validations to a changeset.
  """
  def validate_user_params(changeset) do
    changeset
    |> validate_required([:first_name, :last_name, :email, :password])
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:first_name, min: 1, max: 255)
    |> validate_length(:last_name, min: 1, max: 255)
    |> validate_length(:password, min: 6)
    |> validate_format(:email, email_format(), message: dgettext("errors", "is invalid"))
    |> unique_constraint(:email, name: :users_space_id_email_index)
  end

  defp generate_salt do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase()
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
