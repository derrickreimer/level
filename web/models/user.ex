defmodule Bridge.User do
  @moduledoc """
  A User always belongs to a pod and has a specific role in the pod.
  """

  use Bridge.Web, :model

  schema "users" do
    field :state, :integer
    field :role, :integer
    field :email, :string
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :time_zone, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    belongs_to :pod, Bridge.Pod

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pod_id, :email, :username, :first_name, :last_name, :time_zone, :state, :role, :password_hash])
    |> validate_required([:email, :username, :time_zone])
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:username, min: 1, max: 20)
    |> unique_constraint(:email, name: :users_pod_id_email_index)
    |> unique_constraint(:username, name: :users_pod_id_username_index)
  end

  @doc """
  Builds a changeset for signup based on the `struct` and `params`.
  This method gets used within the Signup.multi function.
  """
  def signup_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pod_id, :email, :username, :time_zone, :password])
    |> put_default_time_zone
    |> put_pass_hash
    |> put_change(:state, 0) # TODO: implement real states
    |> put_change(:role, 0) # TODO: implement real roles
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end

  defp put_default_time_zone(changeset) do
    case changeset do
      %Ecto.Changeset{changes: %{time_zone: ""}} ->
        put_change(changeset, :time_zone, "UTC")
      %Ecto.Changeset{changes: %{time_zone: _}} ->
        changeset
      _ ->
        put_change(changeset, :time_zone, "UTC")
    end
  end
end
