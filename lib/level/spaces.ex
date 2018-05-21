defmodule Level.Spaces do
  @moduledoc """
  The Spaces context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Spaces.OpenInvitation
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceSetupStep
  alias Level.Spaces.SpaceUser
  alias Level.Repo
  alias Level.Users.User

  @behaviour Level.DataloaderSource

  @typedoc "The result of creating a space"
  @type create_space_result ::
          {:ok,
           %{space: Space.t(), space_user: SpaceUser.t(), open_invitation: OpenInvitation.t()}}
          | {:error, :space | :space_user | :open_invitation, any(),
             %{optional(:space | :space_user | :open_invitation) => any()}}

  @typedoc "The result of getting a space"
  @type get_space_result ::
          {:ok, %{space: Space.t(), space_user: SpaceUser.t()}} | {:error, String.t()}

  @typedoc "Possible space setup states"
  @type space_setup_states :: :create_groups | :invite_users | :complete

  @doc """
  Fetches a space by id.
  """
  @spec get_space(User.t(), String.t()) :: get_space_result()
  def get_space(user, id) do
    with %Space{} = space <- Repo.get(Space, id),
         {:ok, space_user} <- get_space_user(user, space) do
      {:ok, %{space: space, space_user: space_user}}
    else
      _ ->
        {:error, dgettext("errors", "Space not found")}
    end
  end

  @doc """
  Fetches a space by slug.
  """
  @spec get_space_by_slug(User.t(), String.t()) :: get_space_result()
  def get_space_by_slug(user, slug) do
    with %Space{} = space <- Repo.get_by(Space, %{slug: slug}),
         %SpaceUser{} = space_user <- Repo.get_by(SpaceUser, user_id: user.id, space_id: space.id) do
      {:ok, %{space: space, space_user: space_user}}
    else
      _ ->
        {:error, dgettext("errors", "Space not found")}
    end
  end

  @doc """
  Creates a new space.
  """
  @spec create_space(User.t(), map()) :: create_space_result()
  def create_space(user, params) do
    Multi.new()
    |> Multi.insert(:space, Space.create_changeset(%Space{}, params))
    |> Multi.run(:space_user, fn %{space: space} -> create_owner(user, space) end)
    |> Multi.run(:open_invitation, fn %{space: space} -> create_open_invitation(space) end)
    |> Repo.transaction()
  end

  @doc """
  Builds a query for list space users linked to given user.
  """
  @spec list_space_users_query(User.t()) :: Ecto.Query.t()
  def list_space_users_query(user) do
    from su in SpaceUser,
      where: su.user_id == ^user.id,
      join: s in Space,
      on: s.id == su.space_id,
      join: u in User,
      on: u.id == su.user_id,
      select: %{su | space_name: s.name, first_name: u.first_name, last_name: u.last_name}
  end

  @doc """
  Fetches a space user.
  """
  @spec get_space_user(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, String.t()}
  @spec get_space_user(User.t(), String.t()) :: {:ok, SpaceUser.t()} | {:error, String.t()}
  def get_space_user(%User{} = user, %Space{} = space) do
    case Repo.get_by(list_space_users_query(user), space_id: space.id) do
      %SpaceUser{} = space_user ->
        {:ok, space_user}

      _ ->
        {:error, dgettext("errors", "User is not a member")}
    end
  end

  def get_space_user(%User{} = user, space_user_id) do
    case Repo.get_by(list_space_users_query(user), id: space_user_id) do
      %SpaceUser{} = space_user ->
        {:ok, space_user}

      _ ->
        {:error, dgettext("errors", "Membership not found")}
    end
  end

  @doc """
  Establishes a user as an owner of space.
  """
  @spec create_owner(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_owner(user, space) do
    %SpaceUser{}
    |> SpaceUser.create_changeset(%{user_id: user.id, space_id: space.id, role: "OWNER"})
    |> Repo.insert()
  end

  @doc """
  Establishes a user as a member of a space.
  """
  @spec create_member(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_member(user, space) do
    %SpaceUser{}
    |> SpaceUser.create_changeset(%{user_id: user.id, space_id: space.id, role: "MEMBER"})
    |> Repo.insert()
  end

  @doc """
  Fetches the active open invitation for a space.
  """
  @spec get_open_invitation(Space.t()) :: {:ok, OpenInvitation.t()} | :revoked
  def get_open_invitation(%Space{} = space) do
    case Repo.get_by(OpenInvitation, space_id: space.id, state: "ACTIVE") do
      %OpenInvitation{} = invitation ->
        {:ok, invitation}

      nil ->
        :revoked
    end
  end

  @doc """
  Fetches an open invitation by token.
  """
  @spec get_open_invitation_by_token(String.t()) ::
          {:ok, OpenInvitation.t()} | {:error, :not_found | :revoked}
  def get_open_invitation_by_token(token) do
    case Repo.get_by(OpenInvitation, token: token) do
      %OpenInvitation{} = invitation ->
        case invitation.state do
          "ACTIVE" ->
            {:ok, invitation}

          _ ->
            {:error, :revoked}
        end

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates an open invitation.
  """
  @spec create_open_invitation(Space.t()) ::
          {:ok, OpenInvitation.t()} | {:error, Ecto.Changeset.t()}
  def create_open_invitation(space) do
    case Repo.get_by(OpenInvitation, space_id: space.id, state: "ACTIVE") do
      %OpenInvitation{} = existing_invitation ->
        existing_invitation
        |> Ecto.Changeset.change(state: "REVOKED")
        |> Repo.update()

        insert_open_invitation(space)

      nil ->
        insert_open_invitation(space)
    end
  end

  defp insert_open_invitation(space) do
    %OpenInvitation{}
    |> OpenInvitation.create_changeset(%{space_id: space.id})
    |> Repo.insert()
  end

  @doc """
  Accepts an open invitation.
  """
  @spec accept_open_invitation(User.t(), OpenInvitation.t()) ::
          {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def accept_open_invitation(user, invitation) do
    invitation = Repo.preload(invitation, :space)
    create_member(user, invitation.space)
  end

  @doc """
  Determines the setup state for a space.
  """
  @spec get_setup_state(Space.t()) :: {:ok, space_setup_states()}
  def get_setup_state(space) do
    completed_states =
      Repo.all(from t in SpaceSetupStep, where: t.space_id == ^space.id, select: t.state)

    next_state =
      cond do
        Enum.member?(completed_states, "INVITE_USERS") -> :complete
        Enum.member?(completed_states, "CREATE_GROUPS") -> :invite_users
        true -> :create_groups
      end

    {:ok, next_state}
  end

  @doc """
  Marks a setup state as complete and returns the current state.

  Uniqueness of state transition records is enforced, but attempting to
  transition the same state multiple times will not result in an error.
  """
  @spec complete_setup_step(SpaceUser.t(), Space.t(), map()) ::
          {:ok, space_setup_states()} | {:error, Ecto.Changeset.t()}
  def complete_setup_step(space_user, space, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, space.id)
      |> Map.put(:space_user_id, space_user.id)
      |> Map.put(:state, params.state |> Atom.to_string() |> String.upcase())

    changeset =
      %SpaceSetupStep{}
      |> SpaceSetupStep.create_changeset(params_with_relations)

    case Repo.insert(changeset) do
      {:ok, _} ->
        get_setup_state(space)

      {:error, %Ecto.Changeset{errors: [state: _]}} ->
        get_setup_state(space)

      error ->
        error
    end
  end

  @doc false
  def dataloader_data(%{current_user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &dataloader_query/2, default_params: params)
  end

  def dataloader_data(_), do: raise(ArgumentError, message: "authentication required")

  @doc false
  def dataloader_query(SpaceUser, %{current_user: user}) do
    list_space_users_query(user)
  end

  def dataloader_query(_, _),
    do: raise(ArgumentError, message: "query not valid for this context")
end
