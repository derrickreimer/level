defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext
  import Ecto.Changeset, only: [change: 2, unique_constraint: 3]

  alias Ecto.Multi
  alias Level.Repo
  alias Level.Groups.Group
  alias Level.Groups.GroupBookmark
  alias Level.Groups.GroupUser
  alias Level.Spaces.SpaceUser

  @doc """
  Generate the query for listing all groups visible to a given member.
  """
  @spec list_groups_query(SpaceUser.t()) :: Ecto.Query.t()
  def list_groups_query(%SpaceUser{id: space_user_id, space_id: space_id}) do
    from g in Group,
      where: g.space_id == ^space_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id and gu.space_user_id == ^space_user_id,
      where: g.is_private == false or (g.is_private == true and not is_nil(gu.id))
  end

  @doc """
  Fetches a group by id.
  """
  @spec get_group(SpaceUser.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group(%SpaceUser{space_id: space_id} = member, id) do
    case Repo.get_by(Group, id: id, space_id: space_id) do
      %Group{} = group ->
        if group.is_private do
          case get_group_membership(group, member) do
            {:ok, _} ->
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

  @doc """
  Creates a group.
  """
  @spec create_group(SpaceUser.t(), map()) ::
          {:ok, %{group: Group.t(), group_user: GroupUser.t(), bookmarked: boolean()}}
          | {:error, :group | :group_user | :bookmark, any(),
             %{optional(:group | :group_user | :bookmark) => any()}}
  def create_group(space_user, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_user.space_id)
      |> Map.put(:creator_id, space_user.id)

    changeset = Group.create_changeset(%Group{}, params_with_relations)

    Multi.new()
    |> Multi.insert(:group, changeset)
    |> Multi.run(:group_user, fn %{group: group} ->
      create_group_membership(group, space_user)
    end)
    |> Multi.run(:bookmarked, fn %{group: group} ->
      case bookmark_group(group, space_user) do
        :ok -> {:ok, true}
        _ -> {:ok, false}
      end
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
  end

  @doc """
  Fetches a group membership by group and user.
  """
  @spec get_group_membership(Group.t(), SpaceUser.t()) ::
          {:ok, GroupUser.t()} | {:error, String.t()}
  def get_group_membership(%Group{id: group_id}, %SpaceUser{id: space_user_id}) do
    case Repo.get_by(GroupUser, space_user_id: space_user_id, group_id: group_id) do
      %GroupUser{} = group_user ->
        {:ok, group_user}

      _ ->
        {:error, dgettext("errors", "The user is a not a group member")}
    end
  end

  @doc """
  Creates a group membership.
  """
  @spec create_group_membership(Group.t(), SpaceUser.t()) ::
          {:ok, GroupUser.t()} | {:error, Ecto.Changeset.t()}
  def create_group_membership(group, space_user) do
    params = %{
      space_id: group.space_id,
      group_id: group.id,
      space_user_id: space_user.id
    }

    %GroupUser{}
    |> GroupUser.changeset(params)
    |> Repo.insert()
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

    case Repo.insert(changeset) do
      {:ok, _} -> :ok
      {:error, %Ecto.Changeset{errors: [uniqueness: _]}} -> :ok
      {:error, _} -> {:error, dgettext("errors", "An unexpected error occurred")}
    end
  end

  @doc """
  Unbookmarks a group.
  """
  @spec unbookmark_group(Group.t(), SpaceUser.t()) :: :ok | no_return()
  def unbookmark_group(group, space_user) do
    Repo.delete_all(
      from b in GroupBookmark,
        where: b.space_user_id == ^space_user.id and b.group_id == ^group.id
    )

    :ok
  end

  @doc """
  Lists all bookmarked groups.
  """
  @spec list_bookmarked_groups(SpaceUser.t()) :: [Group.t()] | no_return()
  def list_bookmarked_groups(space_user) do
    space_user
    |> list_groups_query
    |> join(
      :inner,
      [g],
      b in GroupBookmark,
      b.group_id == g.id and b.space_user_id == ^space_user.id
    )
    |> Repo.all()
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
end
