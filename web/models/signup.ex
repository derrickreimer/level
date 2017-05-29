defmodule Bridge.Signup do
  @moduledoc """
  This is a virtual model whose changeset is designed to be bound to the
  new pod sign up form.
  """

  import Ecto.Changeset
  alias Ecto.Multi

  alias Bridge.Repo
  alias Bridge.Pod
  alias Bridge.User

  @types %{
    pod_name: :string,
    username: :string,
    email: :string,
    password: :string,
    time_zone: :string
  }

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def form_changeset(struct, params \\ %{}) do
    # TODO:
    # - Additional password validation?
    # - Validate email format
    # - Validate username format
    # - Validate uniqueness of email
    # - Validate uniqueness of username
    # - Validate time zone
    # - Gracefully handle DB-level uniqueness violations?
    {struct, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:pod_name, :username, :email, :password])
    |> validate_length(:pod_name, min: 1, max: 255)
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:username, min: 1, max: 20)
    |> validate_length(:username, min: 5)
  end

  @doc """
  Builds an Ecto.Multi operation that will take a changeset and persist the
  new pod and user to the database when passed to `Repo.transaction`.
  """
  def transaction(changeset) do
    pod_changeset = Pod.signup_changeset(%Pod{}, pod_params(changeset))
    user_changeset = User.signup_changeset(%User{}, user_params(changeset))

    Multi.new
    |> Multi.insert(:pod, pod_changeset)
    |> Multi.run(:user, fn %{pod: pod} ->
      user_changeset
      |> put_change(:pod_id, pod.id)
      |> Repo.insert
    end)
  end

  defp pod_params(changeset) do
    %{name: changeset.changes.pod_name}
  end

  defp user_params(changeset) do
    Map.take(changeset.changes, [:username, :email, :password, :time_zone])
  end
end
