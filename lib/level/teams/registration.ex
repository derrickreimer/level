defmodule Level.Teams.Registration do
  @moduledoc """
  This is a virtual model whose form changeset is designed to be bound to the
  new team sign up form.
  """

  import Level.Gettext
  import Ecto.Changeset
  alias Ecto.Multi

  alias Level.Repo
  alias Level.Teams.Team
  alias Level.Teams.User

  @types %{
    slug: :string,
    team_name: :string,
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
    |> validate_required([:slug, :team_name, :first_name, :last_name, :username, :email, :password])
    |> validate_length(:slug, min: 1, max: 20)
    |> validate_format(:slug, Team.slug_format, message: dgettext("errors", "must be lowercase and alphanumeric"))
    |> validate_length(:team_name, min: 1, max: 255)
    |> User.validate_user_params()
    |> validate_slug_uniqueness
  end

  @doc """
  Builds an Ecto.Multi operation that will take a changeset and persist the
  new team and user to the database when passed to `Repo.transaction`.
  """
  def transaction(changeset) do
    team_changeset = Team.signup_changeset(%Team{}, team_params(changeset))
    user_changeset = User.signup_changeset(%User{}, user_params(changeset))

    Multi.new
    |> Multi.insert(:team, team_changeset)
    |> Multi.run(:user, fn %{team: team} ->
      user_changeset
      |> put_change(:team_id, team.id)
      |> Repo.insert
    end)
  end

  defp team_params(changeset) do
    changeset.changes
    |> Map.take([:team_name, :slug])
    |> Map.delete(:team_name)
    |> Map.put(:name, changeset.changes.team_name)
  end

  defp user_params(changeset) do
    changeset.changes
    |> Map.take([:first_name, :last_name, :username, :email, :password, :time_zone])
    |> Map.put(:role, "OWNER")
  end

  def validate_slug_uniqueness(changeset, _opts \\ []) do
    validate_change changeset, :slug, {:uniqueness}, fn _, value ->
      case Repo.get_by(Team, slug: value) do
        nil -> []
        _ -> [{:slug, {dgettext("errors", "is already taken"), [validation: :uniqueness]}}]
      end
    end
  end
end
