defmodule Level.Spaces do
  @moduledoc """
  A space is the fundamental organizational unit in Level. Think of a space like
  a "company" or "organization", just more concise and generically-named.

  All users must be related to a particular space, either as the the owner or
  some other role.
  """

  alias Level.Spaces.Space
  alias Level.Spaces.User
  alias Level.Spaces.Registration
  alias Level.Spaces.Invitation
  alias Level.Repo

  @doc """
  Fetches a space by slug and returns `nil` if not found.
  """
  def get_space_by_slug(slug) do
    Repo.get_by(Space, %{slug: slug})
  end

  @doc """
  Fetches a space by slug and raises an exception if not found.
  """
  def get_space_by_slug!(slug) do
    Repo.get_by!(Space, %{slug: slug})
  end

  @doc """
  Fetches a user by id and returns `nil` if not found.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Fetches a user for a particular space by a identifier (either email or username),
  and returns `nil` if not found.
  """
  def get_user_by_identifier(space, identifier) do
    column = if Regex.match?(~r/@/, identifier) do
      :email
    else
      :username
    end

    params = Map.put(%{space_id: space.id}, column, identifier)
    Repo.get_by(User, params)
  end

  @doc """
  Builds a changeset for performing user registration.
  """
  def registration_changeset(struct, params \\ %{}) do
    Registration.changeset(struct, params)
  end

  @doc """
  Performs user registration from a given changeset.
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
          |> Repo.preload([:space, :invitor])

        invitation
        |> LevelWeb.Email.invitation_email()
        |> Level.Mailer.deliver_later()

        {:ok, invitation}

      error ->
        error
    end
  end

  @doc """
  Fetches a pending invitation by space and token, and raises an exception
  if the record is not found.
  """
  def get_pending_invitation!(space, token) do
    Invitation
    |> Repo.get_by!(space_id: space.id, state: "PENDING", token: token)
    |> Repo.preload([:space, :invitor])
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
