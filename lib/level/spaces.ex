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
  Fetches a space by slug.
  """
  @spec get_space_by_slug(String.t()) :: Space.t() | nil
  def get_space_by_slug(slug) do
    Repo.get_by(Space, %{slug: slug})
  end

  @doc """
  Fetches a space by slug.

  Raises an `Ecto.NoResultsError` exception if not found.
  """
  @spec get_space_by_slug!(String.t()) :: Space.t()
  def get_space_by_slug!(slug) do
    Repo.get_by!(Space, %{slug: slug})
  end

  @doc """
  Fetches a user by id.
  """
  @spec get_user(String.t()) :: User.t() | nil
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Fetches a user by space and email address.
  """
  @spec get_user_by_email(Space.t(), String.t()) :: User.t() | nil
  def get_user_by_email(space, email) do
    Repo.get_by(User, space_id: space.id, email: email)
  end

  @doc """
  Builds a changeset for performing user registration.
  """
  @spec registration_changeset(map(), map()) :: Ecto.Changeset.t()
  def registration_changeset(struct, params \\ %{}) do
    Registration.changeset(struct, params)
  end

  @doc """
  Performs user registration from a given changeset.
  """
  @spec register(Ecto.Changeset.t()) ::
          {:ok, %{space: Space.t(), user: User.t()}}
          | {:error, :space | :user, any(), %{optional(:space | :user) => any()}}
  def register(changeset) do
    changeset
    |> Registration.create_operation()
    |> Repo.transaction()
  end

  @doc """
  Creates an invitation and sends an email to the invited person.
  """
  @spec create_invitation(User.t(), map()) :: {:ok, Invitation.t()} | {:error, Ecto.Changeset.t()}
  def create_invitation(user, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, user.space_id)
      |> Map.put(:invitor_id, user.id)

    changeset = Invitation.changeset(%Invitation{}, params_with_relations)

    case Repo.insert(changeset) do
      {:ok, invitation} ->
        invitation_with_relations =
          invitation
          |> Repo.preload([:space, :invitor])

        _delivered_email =
          invitation_with_relations
          |> LevelWeb.Email.invitation_email()
          |> Level.Mailer.deliver_later()

        {:ok, invitation_with_relations}

      error ->
        error
    end
  end

  @doc """
  Fetches a pending invitation by space and token.

  Raises an `Ecto.NoResultsError` exception if invitation is not found.
  """
  @spec get_pending_invitation!(Space.t(), String.t()) :: Invitation.t()
  def get_pending_invitation!(space, token) do
    Invitation
    |> Repo.get_by!(space_id: space.id, state: "PENDING", token: token)
    |> Repo.preload([:space, :invitor])
  end

  @doc """
  Fetches a pending invitation by space and id.
  """
  @spec get_pending_invitation(Space.t(), String.t()) :: Invitation.t() | nil
  def get_pending_invitation(space, id) do
    Repo.get_by(Invitation, space_id: space.id, state: "PENDING", id: id)
  end

  @doc """
  Registers a user and marks the given invitation as accepted.
  """
  @spec accept_invitation(Invitation.t(), map()) ::
          {:ok, %{user: User.t(), invitation: Invitation.t()}}
          | {:error, :user | :invitation, any(), %{optional(:user | :invitation) => any()}}
  def accept_invitation(invitation, params \\ %{}) do
    invitation
    |> Invitation.accept_operation(params)
    |> Repo.transaction()
  end

  @doc """
  Transitions an invitation to revoked.

  ## Examples

      # If successful, returns the mutated invitation.
      revoke_invitation(invitation)
      => {:ok, %Invitation{...}}

      # Otherwise, returns an error.
      => {:error, message}
  """
  @spec revoke_invitation(Invitation.t()) :: {:ok, Invitation.t()} | {:error, String.t()}
  def revoke_invitation(invitation) do
    invitation
    |> Invitation.revoke_operation()
    |> Repo.update()
  end

  @doc """
  The Ecto data source for use by dataloader.
  """
  @spec data() :: Dataloader.Ecto.t()
  def data do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  @doc """
  The query function for dataloader data.
  """
  def query(queryable, _params) do
    queryable
  end
end
