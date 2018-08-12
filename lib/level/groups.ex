defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext
  import Ecto.Changeset, only: [change: 2, unique_constraint: 3]

  alias Ecto.Multi
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Groups.Group
  alias Level.Groups.GroupBookmark
  alias Level.Groups.GroupUser
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  @behaviour Level.DataloaderSource

  @doc """
  Generate the query for listing all accessible groups.
  """
  @spec groups_base_query(SpaceUser.t()) :: Ecto.Query.t()
  @spec groups_base_query(User.t()) :: Ecto.Query.t()

  def groups_base_query(%SpaceUser{id: space_user_id, space_id: space_id}) do
    from g in Group,
      where: g.space_id == ^space_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id and gu.space_user_id == ^space_user_id,
      where: g.is_private == false or (g.is_private == true and not is_nil(gu.id))
  end

  def groups_base_query(%User{id: user_id}) do
    from g in Group,
      distinct: g.id,
      join: su in SpaceUser,
      on: su.space_id == g.space_id and su.user_id == ^user_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id,
      left_join: gsu in SpaceUser,
      on: gu.space_user_id == gsu.id and gsu.user_id == ^user_id,
      where:
        g.is_private == false or
          (g.is_private == true and not is_nil(gu.id) and not is_nil(gsu.id))
  end

  @doc """
  Fetches a group by id.
  """
  @spec get_group(SpaceUser.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  @spec get_group(User.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}

  def get_group(%SpaceUser{} = member, id) do
    case Repo.get_by(groups_base_query(member), id: id) do
      %Group{} = group ->
        if group.is_private do
          case get_group_user(group, member) do
            {:ok, %GroupUser{} = _} ->
              {:ok, group}

            _ ->
              {:error, dgettext("errors", "Group not found")}
          end
        else
          {:ok, group}
        end

      _ ->
        {:error, dgettext("errors", "Group not found")}
    end
  end

  def get_group(%User{} = user, id) do
    case Repo.get_by(groups_base_query(user), id: id) do
      %Group{} = group ->
        {:ok, group}

      _ ->
        {:error, dgettext("errors", "Group not found")}
    end
  end

  @doc """
  Creates a group.
  """
  @spec create_group(SpaceUser.t(), map()) ::
          {:ok,
           %{group: Group.t(), membership: %{group_user: GroupUser.t(), bookmarked: boolean()}}}
          | {:error, :group | :membership, any(), %{optional(:group | :membership) => any()}}
  def create_group(space_user, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_user.space_id)
      |> Map.put(:creator_id, space_user.id)

    changeset = Group.create_changeset(%Group{}, params_with_relations)

    Multi.new()
    |> Multi.insert(:group, changeset)
    |> Multi.run(:membership, fn %{group: group} ->
      create_group_membership(group, space_user)
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a group.
  """
  @spec update_group(Group.t(), map()) :: {:ok, Group.t()} | {:error, Ecto.Changeset.t()}
  def update_group(group, params) do
    group
    |> Group.update_changeset(params)
    |> Repo.update()
    |> after_update_group()
  end

  defp after_update_group({:ok, %Group{id: id} = group} = result) do
    Pubsub.publish(:group_updated, id, group)
    result
  end

  defp after_update_group(err), do: err

  @doc """
  Fetches a group membership by group and user.
  """
  @spec get_group_user(Group.t(), SpaceUser.t()) :: {:ok, GroupUser.t() | nil}
  @spec get_group_user(Group.t(), User.t()) :: {:ok, GroupUser.t() | nil}

  def get_group_user(%Group{id: group_id}, %SpaceUser{id: space_user_id}) do
    GroupUser
    |> Repo.get_by(space_user_id: space_user_id, group_id: group_id)
    |> handle_get_group_user()
  end

  def get_group_user(%Group{id: group_id}, %User{id: user_id}) do
    queryable =
      from gu in GroupUser,
        join: su in assoc(gu, :space_user),
        where: su.user_id == ^user_id

    queryable
    |> Repo.get_by(group_id: group_id)
    |> handle_get_group_user()
  end

  defp handle_get_group_user(%GroupUser{} = group_user), do: {:ok, group_user}
  defp handle_get_group_user(_), do: {:ok, nil}

  @doc """
  Lists featured group memberships (for display in the sidebar).

  Currently returns the top ten users, ordered alphabetically.
  """
  @spec list_featured_memberships(Group.t()) :: {:ok, [GroupUser.t()]} | no_return()
  def list_featured_memberships(group) do
    base_query =
      from gu in GroupUser,
        where: gu.group_id == ^group.id,
        join: u in assoc(gu, :user),
        select: %{gu | last_name: u.last_name}

    query =
      from gu in subquery(base_query),
        order_by: {:asc, gu.last_name},
        limit: 10

    {:ok, Repo.all(query)}
  end

  @doc """
  Creates a group membership.
  """
  @spec create_group_membership(Group.t(), SpaceUser.t()) ::
          {:ok, %{group_user: GroupUser.t(), bookmarked: boolean()}}
          | {:error, :group_user | :bookmarked, any(),
             %{optional(:group_user | :bookmarked) => any()}}
  def create_group_membership(group, space_user) do
    params = %{
      space_id: group.space_id,
      group_id: group.id,
      space_user_id: space_user.id
    }

    Multi.new()
    |> Multi.insert(:group_user, GroupUser.changeset(%GroupUser{}, params))
    |> Multi.run(:bookmarked, fn _ ->
      case bookmark_group(group, space_user) do
        :ok -> {:ok, true}
        _ -> {:ok, false}
      end
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes a group membership.
  """
  @spec delete_group_membership(Group.t(), SpaceUser.t(), GroupUser.t()) ::
          {:ok, %{group_user: GroupUser.t(), unbookmarked: boolean()}}
          | {:error, :group_user | :unbookmarked, any(),
             %{optional(:group_user | :unbookmarked) => any()}}
          | no_return()
  def delete_group_membership(group, space_user, group_user) do
    Multi.new()
    |> Multi.delete(:group_user, group_user)
    |> Multi.run(:unbookmarked, fn _ ->
      unbookmark_group(group, space_user)
      {:ok, true}
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates group membership state.
  """
  @spec update_group_membership(Group.t(), SpaceUser.t(), String.t()) ::
          {:ok, %{group: Group.t(), group_user: GroupUser.t() | nil}}
          | {:error, GroupUser.t() | nil, Ecto.Changeset.t()}
  def update_group_membership(group, space_user, state) do
    case {get_group_user(group, space_user), state} do
      {{:ok, %GroupUser{} = group_user}, "NOT_SUBSCRIBED"} ->
        case delete_group_membership(group, space_user, group_user) do
          {:ok, _} ->
            Pubsub.publish(:group_membership_updated, group.id, {group, nil})
            {:ok, %{group: group, group_user: nil}}

          {:error, _, %Ecto.Changeset{} = changeset, _} ->
            {:error, group_user, changeset}
        end

      {{:ok, nil}, "SUBSCRIBED"} ->
        case create_group_membership(group, space_user) do
          {:ok, %{group_user: group_user}} ->
            Pubsub.publish(:group_membership_updated, group.id, {group, group_user})
            {:ok, %{group: group, group_user: group_user}}

          {:error, _, %Ecto.Changeset{} = changeset, _} ->
            {:error, nil, changeset}
        end

      {{:ok, %GroupUser{} = group_user}, _} ->
        {:ok, %{group: group, group_user: group_user}}

      {{:ok, nil}, _} ->
        {:ok, %{group: group, group_user: nil}}
    end
  end

  @doc """
  Bookmarks a group.
  """
  @spec bookmark_group(Group.t(), SpaceUser.t()) :: :ok | {:error, String.t()}
  def bookmark_group(group, space_user) do
    params = %{
      space_id: group.space_id,
      space_user_id: space_user.id,
      group_id: group.id
    }

    changeset =
      %GroupBookmark{}
      |> change(params)
      |> unique_constraint(:uniqueness, name: :group_bookmarks_space_user_id_group_id_index)

    case Repo.insert(changeset, on_conflict: :nothing) do
      {:ok, _} ->
        Pubsub.publish(:group_bookmarked, space_user.id, group)
        :ok

      {:error, %Ecto.Changeset{errors: [uniqueness: _]}} ->
        :ok

      {:error, _} ->
        {:error, dgettext("errors", "An unexpected error occurred")}
    end
  end

  @doc """
  Unbookmarks a group.
  """
  @spec unbookmark_group(Group.t(), SpaceUser.t()) :: :ok | no_return()
  def unbookmark_group(group, space_user) do
    {count, _} =
      Repo.delete_all(
        from b in GroupBookmark,
          where: b.space_user_id == ^space_user.id and b.group_id == ^group.id
      )

    if count > 0 do
      Pubsub.publish(:group_unbookmarked, space_user.id, group)
    end

    :ok
  end

  @doc """
  Lists all bookmarked groups.
  """
  @spec list_bookmarked_groups(SpaceUser.t()) :: [Group.t()] | no_return()
  def list_bookmarked_groups(space_user) do
    space_user
    |> groups_base_query
    |> join(
      :inner,
      [g],
      b in GroupBookmark,
      b.group_id == g.id and b.space_user_id == ^space_user.id
    )
    |> Repo.all()
  end

  @doc """
  Determines if a group is bookmarked.
  """
  @spec is_bookmarked(User.t(), Group.t()) :: boolean()
  def is_bookmarked(%User{id: user_id}, %Group{id: group_id}) do
    query =
      from b in GroupBookmark,
        join: su in assoc(b, :space_user),
        where: su.user_id == ^user_id and b.group_id == ^group_id

    Repo.one(query) != nil
  end

  @doc """
  Closes a group.
  """
  @spec close_group(Group.t()) :: {:ok, Group.t()} | {:error, Ecto.Changeset.t()}
  def close_group(group) do
    group
    |> Ecto.Changeset.change(state: "CLOSED")
    |> Repo.update()
  end

  @impl true
  def dataloader_data(%{current_user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &dataloader_query/2, default_params: params)
  end

  def dataloader_data(_), do: raise("authentication required")

  @impl true
  def dataloader_query(Group, %{current_user: user}), do: groups_base_query(user)

  def dataloader_query(GroupBookmark, %{current_user: %User{id: user_id}}) do
    from b in GroupBookmark,
      join: su in assoc(b, :space_user),
      where: su.user_id == ^user_id
  end

  def dataloader_query(GroupUser, %{current_user: %User{id: user_id}}) do
    from gu in GroupUser,
      join: su in assoc(gu, :space_user),
      where: su.user_id == ^user_id
  end

  def dataloader_query(_, _), do: raise("query not valid for this context")
end
