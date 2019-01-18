defmodule Level.Schemas.User do
  @moduledoc """
  The User schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Level.Gettext

  alias Comeonin.Bcrypt
  alias Ecto.Changeset
  alias Level.Handles
  alias Level.OlsonTimeZone
  alias Level.Schemas.PushSubscription
  alias Level.Schemas.SpaceUser
  alias Level.Users

  @type t :: %__MODULE__{}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # @states ["ACTIVE", "DISABLED"]
  # @roles ["OWNER", "ADMIN", "MEMBER"]

  schema "users" do
    field :state, :string, read_after_writes: true
    field :email, :string
    field :handle, :string
    field :first_name, :string, default: ""
    field :last_name, :string, default: ""
    field :time_zone, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :session_salt, :string
    field :avatar, :string
    has_many :space_users, SpaceUser
    has_many :push_subscriptions, PushSubscription

    timestamps()
  end

  @doc """
  Generates a display name for a user.
  """
  def display_name(%__MODULE__{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  @doc """
  The regex format for an email address.
  Borrowed from http://www.regular-expressions.info/email.html
  """
  def email_format do
    ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:email, :handle, :first_name, :last_name, :password, :time_zone])
    |> validate_required([:first_name, :last_name, :handle, :email, :password])
    |> put_default_time_zone()
    |> validate()
    |> put_password_hash()
    |> put_change(:session_salt, generate_salt())
  end

  @doc false
  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:email, :handle, :first_name, :last_name, :password, :time_zone, :avatar])
    |> validate_required([:email, :handle, :first_name, :last_name])
    |> validate()
    |> put_password_hash()
  end

  @doc false
  def reset_password_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6)
    |> put_password_hash()
  end

  @doc """
  Applies user attribute validations to a changeset.
  """
  def validate(changeset) do
    changeset
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:first_name, min: 1, max: 255)
    |> validate_length(:last_name, min: 1, max: 255)
    |> validate_length(:password, min: 6)
    |> validate_format(:email, email_format(), message: dgettext("errors", "is invalid"))
    |> Handles.validate_format(:handle)
    |> OlsonTimeZone.validate(:time_zone)
    |> validate_reservations()
    |> unique_constraint(:email,
      name: :users_lower_email_index,
      message: dgettext("errors", "is already taken")
    )
    |> unique_constraint(:handle,
      name: :users_lower_handle_index,
      message: dgettext("errors", "is already taken")
    )
  end

  defp generate_salt do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
    |> String.downcase()
  end

  defp put_password_hash(changeset) do
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

  defp validate_reservations(changeset) do
    validate_change(changeset, :handle, fn _, handle ->
      check_reservation(changeset, handle)
    end)
  end

  defp check_reservation(changeset, handle) do
    case Users.get_reservation(handle) do
      {:ok, reservation} ->
        if Changeset.get_field(changeset, :email) == reservation.email do
          []
        else
          [{:handle, "is already reserved by another email address"}]
        end

      _ ->
        []
    end
  end
end
