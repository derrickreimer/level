defmodule Level.Spaces.Registration do
  @moduledoc """
  This is a virtual model whose form changeset is designed to be bound to the
  new space sign up form.
  """

  import Level.Gettext
  import Ecto.Changeset
  alias Ecto.Multi

  alias Level.Repo
  alias Level.Spaces.Space
  alias Level.Spaces.User
  alias Level.Rooms

  @types %{
    slug: :string,
    space_name: :string,
    first_name: :string,
    last_name: :string,
    username: :string,
    email: :string,
    password: :string,
    time_zone: :string
  }

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    {struct, @types}
    |> cast(params, Map.keys(@types))
    |> validate_required([:slug, :space_name, :first_name, :last_name, :username, :email, :password])
    |> validate_length(:slug, min: 1, max: 20)
    |> validate_format(:slug, Space.slug_format, message: dgettext("errors", "must be lowercase and alphanumeric"))
    |> validate_length(:space_name, min: 1, max: 255)
    |> User.validate_user_params()
    |> validate_slug_uniqueness
  end

  @doc """
  Builds an Ecto.Multi operation that will take a changeset and persist the
  new space and user to the database when passed to `Repo.transaction`.
  """
  def transaction(changeset) do
    space_changeset = Space.signup_changeset(%Space{}, space_params(changeset))
    user_changeset = User.signup_changeset(%User{}, user_params(changeset))

    Multi.new
    |> Multi.insert(:space, space_changeset)
    |> Multi.run(:user, fn %{space: space} ->
      user_changeset
      |> put_change(:space_id, space.id)
      |> Repo.insert
    end)
    |> Multi.run(:default_room, fn %{user: user} ->
      Rooms.create_room(user, %{
        name: "Everyone",
        description: gettext("This room is for chatter across the entire space."),
        is_private: false
      })
    end)
  end

  defp space_params(changeset) do
    changeset.changes
    |> Map.take([:space_name, :slug])
    |> Map.delete(:space_name)
    |> Map.put(:name, changeset.changes.space_name)
  end

  defp user_params(changeset) do
    changeset.changes
    |> Map.take([:first_name, :last_name, :username, :email, :password, :time_zone])
    |> Map.put(:role, "OWNER")
  end

  def validate_slug_uniqueness(changeset, _opts \\ []) do
    validate_change changeset, :slug, {:uniqueness}, fn _, value ->
      case Repo.get_by(Space, slug: value) do
        nil -> []
        _ -> [{:slug, {dgettext("errors", "is already taken"), [validation: :uniqueness]}}]
      end
    end
  end
end
