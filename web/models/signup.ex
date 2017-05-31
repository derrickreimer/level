defmodule Bridge.Signup do
  @moduledoc """
  This is a virtual model whose form changeset is designed to be bound to the
  new pod sign up form.
  """

  import Bridge.Gettext
  import Ecto.Changeset
  alias Ecto.Multi

  alias Bridge.Repo
  alias Bridge.Pod
  alias Bridge.User

  @types %{
    slug: :string,
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
    {struct, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:slug, :pod_name, :username, :email, :password])
    |> validate_length(:slug, min: 1, max: 20)
    |> validate_length(:pod_name, min: 1, max: 255)
    |> validate_length(:email, min: 1, max: 254)
    |> validate_length(:username, min: 3, max: 20)
    |> validate_length(:password, min: 6)
    |> validate_format(:slug, Pod.slug_format, message: dgettext("errors", "must be lowercase and alphanumeric"))
    |> validate_format(:username, User.username_format, message: dgettext("errors", "must be lowercase and alphanumeric"))
    |> validate_format(:email, User.email_format, message: dgettext("errors", "is invalid"))
    |> validate_slug_uniqueness
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
    changeset.changes
    |> Map.take([:pod_name, :slug])
    |> Map.delete(:pod_name)
    |> Map.put(:name, changeset.changes.pod_name)
  end

  defp user_params(changeset) do
    changeset.changes
    |> Map.take([:username, :email, :password, :time_zone])
  end

  def validate_slug_uniqueness(changeset, _opts \\ []) do
    validate_change changeset, :slug, {:uniqueness}, fn _, value ->
      case Repo.get_by(Pod, slug: value) do
        nil -> []
        _ -> [{:slug, {dgettext("errors", "is already taken"), [validation: :uniqueness]}}]
      end
    end
  end
end
