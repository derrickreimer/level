defmodule Level.Spaces do
  @moduledoc """
  The Spaces context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Level.AssetStore
  alias Level.Bots
  alias Level.Events
  alias Level.Repo
  alias Level.Schemas.OpenInvitation
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceSetupStep
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  @typedoc "The result of creating a space"
  @type create_space_result ::
          {:ok,
           %{
             space: Space.t(),
             space_user: SpaceUser.t(),
             open_invitation: OpenInvitation.t(),
             levelbot: SpaceBot.t()
           }}
          | {:error, :space | :space_user | :open_invitation | :levelbot, any(),
             %{optional(:space | :space_user | :open_invitation | :levelbot) => any()}}

  @typedoc "The result of getting a space"
  @type get_space_result ::
          {:ok, %{space: Space.t(), space_user: SpaceUser.t()}} | {:error, String.t()}

  @typedoc "Possible space setup states"
  @type space_setup_states :: :create_groups | :invite_users | :complete

  @doc """
  Builds a query for listing spaces accessible by a given user.
  """
  @spec spaces_base_query(User.t()) :: Ecto.Query.t()
  def spaces_base_query(user) do
    from s in Space,
      join: su in assoc(s, :space_users),
      where: su.user_id == ^user.id and su.state == "ACTIVE"
  end

  @doc """
  Fetches all spaces the user belongs to.
  """
  @spec list_member_spaces(User.t()) :: [Space.t()]
  def list_member_spaces(%User{} = user) do
    user
    |> spaces_base_query()
    |> order_by(asc: :name)
    |> Repo.all()
  end

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
         {:ok, space_user} <- get_space_user(user, space) do
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
    |> Multi.run(:levelbot, fn %{space: space} -> install_levelbot(space) end)
    |> Repo.transaction()
  end

  defp install_levelbot(space) do
    bot = Bots.get_level_bot!()

    params = %{
      space_id: space.id,
      bot_id: bot.id,
      handle: bot.handle,
      display_name: bot.display_name,
      avatar: bot.avatar
    }

    %SpaceBot{}
    |> Changeset.change(params)
    |> Repo.insert()
  end

  @doc """
  Updates a space.
  """
  @spec update_space(Space.t(), map()) :: {:ok, Space.t()} | {:error, Ecto.Changeset.t()}
  def update_space(space, params) do
    space
    |> Space.update_changeset(params)
    |> Repo.update()
    |> handle_space_update()
  end

  defp handle_space_update({:ok, space} = result) do
    Events.space_updated(space.id, space)
    result
  end

  defp handle_space_update(err), do: err

  @doc """
  Updates a space's avatar.
  """
  @spec update_avatar(Space.t(), String.t()) ::
          {:ok, Space.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def update_avatar(space, raw_data) do
    raw_data
    |> AssetStore.persist_avatar()
    |> set_space_avatar(space)
  end

  defp set_space_avatar({:ok, filename}, space) do
    update_space(space, %{avatar: filename})
  end

  defp set_space_avatar(:error, _space) do
    {:error, dgettext("errors", "An error occurred updating your avatar")}
  end

  @doc """
  Builds a query for listing space users related to the given resource.
  """
  @spec space_users_base_query(User.t()) :: Ecto.Query.t()
  @spec space_users_base_query(Space.t()) :: Ecto.Query.t()

  def space_users_base_query(%User{} = user) do
    from su in SpaceUser,
      distinct: su.id,
      join: s in assoc(su, :space),
      join: usu in SpaceUser,
      on: usu.space_id == su.space_id and usu.user_id == ^user.id,
      select: %{su | space_name: s.name}
  end

  def space_users_base_query(%Space{} = space) do
    from su in SpaceUser,
      join: s in assoc(su, :space),
      where: su.space_id == ^space.id,
      select: %{su | space_name: s.name}
  end

  @doc """
  Fetches all the featured users (for display in the inbox sidebar).
  """
  @spec list_featured_users(Space.t()) :: {:ok, [SpaceUser.t()]} | no_return()
  def list_featured_users(%Space{} = space) do
    result =
      space
      |> space_users_base_query()
      |> order_by([su, s], asc: su.last_name)
      |> limit(10)
      |> Repo.all()

    {:ok, result}
  end

  @doc """
  Fetches a space user.
  """
  @spec get_space_user(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, String.t()}
  @spec get_space_user(User.t(), String.t()) :: {:ok, SpaceUser.t()} | {:error, String.t()}
  def get_space_user(%User{} = user, %Space{} = space) do
    case Repo.get_by(space_users_base_query(user), user_id: user.id, space_id: space.id) do
      %SpaceUser{} = space_user ->
        {:ok, space_user}

      _ ->
        {:error, dgettext("errors", "Space user not found")}
    end
  end

  def get_space_user(%User{} = user, space_user_id) do
    case Repo.get_by(space_users_base_query(user), id: space_user_id) do
      %SpaceUser{} = space_user ->
        {:ok, space_user}

      _ ->
        {:error, dgettext("errors", "Space user not found")}
    end
  end

  @doc """
  Establishes a user as an owner of space.
  """
  @spec create_owner(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_owner(user, space) do
    %SpaceUser{}
    |> SpaceUser.create_changeset(%{
      user_id: user.id,
      space_id: space.id,
      role: "OWNER",
      first_name: user.first_name,
      last_name: user.last_name,
      handle: user.handle,
      avatar: user.avatar
    })
    |> Repo.insert()
  end

  @doc """
  Establishes a user as a member of a space.
  """
  @spec create_member(User.t(), Space.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_member(user, space) do
    %SpaceUser{}
    |> SpaceUser.create_changeset(%{
      user_id: user.id,
      space_id: space.id,
      role: "MEMBER",
      first_name: user.first_name,
      last_name: user.last_name,
      handle: user.handle,
      avatar: user.avatar
    })
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

  @doc """
  Updates a space user.
  """
  @spec update_space_user(SpaceUser.t(), map()) ::
          {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def update_space_user(space_user, params) do
    space_user
    |> SpaceUser.update_changeset(params)
    |> Repo.update()
    |> handle_space_user_update()
  end

  defp handle_space_user_update({:ok, %SpaceUser{} = space_user} = result) do
    Events.space_user_updated(space_user.space_id, space_user)
    result
  end

  defp handle_space_user_update(err), do: err
end
