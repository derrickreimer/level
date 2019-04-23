defmodule Level.Spaces do
  @moduledoc """
  The Spaces context.
  """

  import Ecto.Query
  import Level.Gettext

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Level.AssetStore
  alias Level.Events
  alias Level.Groups
  alias Level.Levelbot
  alias Level.Postbot
  alias Level.Repo
  alias Level.Schemas.Bot
  alias Level.Schemas.OpenInvitation
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceSetupStep
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User
  alias Level.Spaces.CreateDemo
  alias Level.Spaces.JoinSpace
  alias Level.Users

  @typedoc "The result of creating a space"
  @type create_space_result ::
          {:ok,
           %{
             space: Space.t(),
             space_user: SpaceUser.t(),
             open_invitation: OpenInvitation.t(),
             levelbot: SpaceBot.t(),
             postbot: SpaceBot.t(),
             default_group: Group.t()
           }}
          | {:error,
             :space | :space_user | :open_invitation | :levelbot | :postbot | :default_group,
             any(),
             %{
               optional(
                 :space
                 | :space_user
                 | :open_invitation
                 | :levelbot
                 | :postbot
                 | :default_group
               ) => any()
             }}

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
      where: s.state == "ACTIVE",
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
  Fetches the first space that a user belongs to.
  """
  @spec get_first_member_space(User.t()) :: Space.t() | nil
  def get_first_member_space(%User{} = user) do
    user
    |> spaces_base_query()
    |> order_by(asc: :name)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Fetches a space by id.
  """
  @spec get_space(User.t(), String.t()) :: get_space_result()
  def get_space(user, id) do
    with %Space{} = space <- Repo.get_by(Space, id: id, state: "ACTIVE"),
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
  @spec get_space_by_slug(String.t()) :: {:ok, Space.t()} | {:error, String.t()}
  def get_space_by_slug(slug) do
    case Repo.get_by(Space, slug: slug, state: "ACTIVE") do
      %Space{} = space ->
        {:ok, space}

      _ ->
        {:error, dgettext("errors", "Space not found")}
    end
  end

  @spec get_space_by_slug(User.t(), String.t()) :: get_space_result()
  def get_space_by_slug(user, slug) do
    with %Space{} = space <- Repo.get_by(Space, slug: slug, state: "ACTIVE"),
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
  @spec create_space(User.t(), map(), list()) :: create_space_result()
  def create_space(user, params, opts \\ []) do
    Multi.new()
    |> Multi.insert(:space, Space.create_changeset(%Space{}, params))
    |> Multi.run(:levelbot, fn %{space: space} -> Levelbot.install_bot(space) end)
    |> Multi.run(:postbot, fn %{space: space} -> Postbot.install_bot(space) end)
    |> Multi.run(:open_invitation, fn %{space: space} -> create_open_invitation(space) end)
    |> Repo.transaction()
    |> after_create_space(user, opts)
  end

  defp create_everyone_group(space_user) do
    case Groups.create_group(space_user, %{name: "everyone", is_default: true}) do
      {:ok, %{group: group}} ->
        {:ok, group}

      err ->
        err
    end
  end

  defp after_create_space({:ok, %{space: space} = data}, user, opts) do
    {:ok, owner} = create_owner(user, space, opts)
    {:ok, default_group} = create_everyone_group(owner)
    Events.space_joined(user.id, space, owner)

    if !space.is_demo do
      Users.track_analytics_event(user, "Created a team", %{
        team_id: space.id,
        team_name: space.name,
        team_slug: space.slug
      })
    end

    {:ok, Map.merge(data, %{space_user: owner, default_group: default_group})}
  end

  defp after_create_space(err, _, _), do: err

  @doc """
  Creates a demo space.
  """
  @spec create_demo_space(User.t()) :: {:ok, Space.t()}
  def create_demo_space(user) do
    CreateDemo.perform(user)
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
      where: s.state == "ACTIVE",
      where: usu.state == "ACTIVE",
      select: %{su | space_name: s.name}
  end

  def space_users_base_query(%Space{id: space_id}) do
    from su in SpaceUser,
      join: s in assoc(su, :space),
      where: s.state == "ACTIVE",
      where: s.id == ^space_id,
      select: %{su | space_name: s.name}
  end

  @doc """
  Builds a query for listing space bots visible to the given resource.
  """
  @spec space_bots_base_query(User.t()) :: Ecto.Query.t()
  def space_bots_base_query(%User{id: user_id}) do
    from sb in SpaceBot,
      join: s in assoc(sb, :space),
      join: su in SpaceUser,
      on: su.space_id == sb.space_id,
      where: s.state == "ACTIVE",
      where: su.user_id == ^user_id
  end

  @doc """
  Fetches all the featured users (for display in the inbox sidebar).
  """
  @spec list_featured_users(Space.t()) :: {:ok, [SpaceUser.t()]} | no_return()
  def list_featured_users(%Space{} = space) do
    result =
      space
      |> space_users_base_query()
      |> where([su], su.state == "ACTIVE")
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
  def get_space_user(%User{id: user_id} = user, %Space{id: space_id}) do
    query =
      user
      |> space_users_base_query()
      |> where([su], su.space_id == ^space_id and su.user_id == ^user_id)

    case Repo.one(query) do
      %SpaceUser{} = space_user ->
        {:ok, space_user}

      _ ->
        {:error, dgettext("errors", "Space user not found")}
    end
  end

  def get_space_user(%User{} = user, space_user_id) do
    query =
      user
      |> space_users_base_query()
      |> where([su], su.id == ^space_user_id)

    case Repo.one(query) do
      %SpaceUser{} = space_user ->
        {:ok, space_user}

      _ ->
        {:error, dgettext("errors", "Space user not found")}
    end
  end

  @doc """
  Establishes a user as an owner of space.
  """
  @spec create_owner(User.t(), Space.t(), list()) ::
          {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_owner(user, space, opts \\ []) do
    JoinSpace.perform(user, space, "OWNER", opts)
  end

  @doc """
  Establishes a user as a member of a space.
  """
  @spec create_member(User.t(), Space.t(), list()) ::
          {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def create_member(user, space, opts \\ []) do
    JoinSpace.perform(user, space, "MEMBER", opts)
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

    case Repo.get_by(SpaceUser, user_id: user.id, space_id: invitation.space_id) do
      %SpaceUser{state: "DISABLED"} = space_user ->
        grant_access(space_user)

      %SpaceUser{state: "ACTIVE"} = space_user ->
        {:ok, space_user}

      _ ->
        create_member(user, invitation.space)
    end
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

  @doc """
  Updates a space user's role.
  """
  @spec update_role(SpaceUser.t(), SpaceUser.t(), atom()) ::
          {:ok, SpaceUser.t()} | {:error, String.t()} | {:error, Ecto.Changeset.t()}
  def update_role(updater, space_user, "ADMIN") do
    if can_manage_members?(updater) do
      update_space_user(space_user, %{role: "ADMIN"})
    else
      {:error, "You are not allowed to perform this action."}
    end
  end

  def update_role(updater, space_user, "MEMBER") do
    if can_manage_members?(updater) do
      update_space_user(space_user, %{role: "MEMBER"})
    else
      {:error, "You are not allowed to perform this action."}
    end
  end

  def update_role(updater, space_user, "OWNER") do
    if can_manage_owners?(updater) do
      update_space_user(space_user, %{role: "OWNER"})
    else
      {:error, dgettext("errors", "You are not allowed to perform this action.")}
    end
  end

  @doc """
  Determines if a user is allowed to update a space.
  """
  @spec can_update?(SpaceUser.t()) :: boolean()
  def can_update?(%SpaceUser{role: role}) do
    role == "OWNER" || role == "ADMIN"
  end

  @doc """
  Determines if a user is allowed to manage members.
  """
  @spec can_manage_members?(SpaceUser.t()) :: boolean()
  def can_manage_members?(%SpaceUser{role: role}) do
    role == "OWNER" || role == "ADMIN"
  end

  @doc """
  Determines if a user is allowed to manage members.
  """
  @spec can_manage_owners?(SpaceUser.t()) :: boolean()
  def can_manage_owners?(%SpaceUser{role: role}) do
    role == "OWNER"
  end

  @doc """
  Revokes a user's access.
  """
  @spec revoke_access(SpaceUser.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def revoke_access(%SpaceUser{} = space_user) do
    space_user
    |> Ecto.Changeset.change(state: "DISABLED")
    |> Repo.update()
  end

  @doc """
  Grant a space user access.
  """
  @spec grant_access(SpaceUser.t()) :: {:ok, SpaceUser.t()} | {:error, Ecto.Changeset.t()}
  def grant_access(%SpaceUser{} = space_user) do
    space_user
    |> Ecto.Changeset.change(state: "ACTIVE")
    |> Repo.update()
  end

  @doc """
  Installs a bot in a space.
  """
  @spec install_bot(Space.t(), Bot.t()) :: {:ok, SpaceBot.t()} | {:error, Ecto.Changeset.t()}
  def install_bot(%Space{} = space, %Bot{} = bot) do
    params = %{
      space_id: space.id,
      bot_id: bot.id,
      handle: bot.handle,
      display_name: bot.display_name,
      avatar: bot.avatar
    }

    %SpaceBot{}
    |> Changeset.change(params)
    |> Repo.insert(on_conflict: :nothing)
  end
end
