defmodule Bridge.Teams do
  @moduledoc """
  A team is the fundamental organizational unit in Bridge. Think of a team like
  a "company" or "organization", just more concise and generically-named.

  All users must be related to a particular team, either as the the owner or
  some other role.
  """

  alias Bridge.Teams.Team
  alias Bridge.Teams.User
  alias Bridge.Teams.Registration
  alias Bridge.Teams.Invitation
  alias Bridge.Repo

  @doc """
  Fetches a team by slug and returns `nil` if not found.
  """
  def get_team_by_slug(slug) do
    Repo.get_by(Team, %{slug: slug})
  end

  @doc """
  Fetches a team by slug and raises an exception if not found.
  """
  def get_team_by_slug!(slug) do
    Repo.get_by!(Team, %{slug: slug})
  end

  @doc """
  Fetches a user by id and returns `nil` if not found.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Fetches a user for a particular team by a identifier (either email or username),
  and returns `nil` if not found.
  """
  def get_user_by_identifier(team, identifier) do
    column = if Regex.match?(~r/@/, identifier) do
      :email
    else
      :username
    end

    params = Map.put(%{team_id: team.id}, column, identifier)
    Repo.get_by(User, params)
  end

  @doc """
  Builds a changeset for performing user registration.
  """
  def registration_changeset(struct, params \\ %{}) do
    Registration.changeset(struct, params)
  end

  @doc """
  Performs user registration and team creation, given a changeset.
  """
  def register(changeset) do
    changeset
    |> Registration.transaction()
    |> Repo.transaction()
  end

  @doc """
  Builds a changeset for creating an invitation.
  """
  def create_invitation_changeset(params \\ %{}) do
    Invitation.changeset(%Invitation{}, params)
  end

  @doc """
  Creates an invitation and sends an email to the invited person.
  """
  def create_invitation(changeset) do
    case Repo.insert(changeset) do
      {:ok, invitation} ->
        invitation =
          invitation
          |> Repo.preload([:team, :invitor])

        invitation
        |> BridgeWeb.Email.invitation_email()
        |> Bridge.Mailer.deliver_later()

        {:ok, invitation}

      error ->
        error
    end
  end

  @doc """
  Fetches a pending invitation by team and token, and raises an exception
  if the record is not found.
  """
  def get_pending_invitation!(team, token) do
    Invitation
    |> Repo.get_by!(team_id: team.id, state: "PENDING", token: token)
    |> Repo.preload([:team, :invitor])
  end

  @doc """
  Registers a user and marks the given invitation as accepted.
  """
  def accept_invitation(invitation, params \\ %{}) do
    invitation
    |> Invitation.accept_transaction(params)
    |> Repo.transaction()
  end
end
