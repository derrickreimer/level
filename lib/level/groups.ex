defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Changeset, only: [change: 2, unique_constraint: 3]
  import Ecto.Query, warn: false
  import Level.Gettext

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Level.Events
  alias Level.Repo
  alias Level.Schemas.Group
  alias Level.Schemas.GroupBookmark
  alias Level.Schemas.GroupUser
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

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
      join: su in SpaceUser,
      on: su.space_id == g.space_id and su.user_id == ^user_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id and gu.space_user_id == su.id,
      where: g.is_private == false or (g.is_private == true and not is_nil(gu.id))
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
  @spec create_group(SpaceUser.t(), map()) :: {:ok, %{group: Group.t()}} | {:error, Changeset.t()}
  def create_group(space_user, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_user.space_id)
      |> Map.put(:creator_id, space_user.id)

    %Group{}
    |> Group.create_changeset(params_with_relations)
    |> Repo.insert()
    |> after_create_group(space_user)
  end

  defp after_create_group({:ok, group}, space_user) do
    subscribe(group, space_user)
    set_owner_role(group, space_user)
    bookmark_group(group, space_user)
    {:ok, %{group: group}}
  end

  defp after_create_group(err, _) do
    err
  end

  @doc """
  Updates a group.
  """
  @spec update_group(Group.t(), map()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def update_group(group, params) do
    group
    |> Group.update_changeset(params)
    |> Repo.update()
    |> after_update_group()
  end

  defp after_update_group({:ok, %Group{id: id} = group} = result) do
    Events.group_updated(id, group)
    result
  end

  defp after_update_group(err), do: err

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
  Updates group membership state.
  """
  @spec update_group_membership(Group.t(), SpaceUser.t(), String.t()) ::
          {:ok, %{group: Group.t(), group_user: GroupUser.t() | nil}}
          | {:error, GroupUser.t() | nil, Changeset.t()}
  def update_group_membership(group, space_user, state) do
    case {get_group_user(group, space_user), state} do
      {{:ok, %GroupUser{} = group_user}, "NOT_SUBSCRIBED"} ->
        case delete_group_membership(group, space_user, group_user) do
          {:ok, _} ->
            Events.group_membership_updated(group.id, {group, nil})
            {:ok, %{group: group, group_user: nil}}

          {:error, _, %Changeset{} = changeset, _} ->
            {:error, group_user, changeset}
        end

      {{:ok, nil}, "SUBSCRIBED"} ->
        case create_group_membership(group, space_user) do
          {:ok, %{group_user: group_user}} ->
            Events.group_membership_updated(group.id, {group, group_user})
            {:ok, %{group: group, group_user: group_user}}

          {:error, _, %Changeset{} = changeset, _} ->
            {:error, nil, changeset}
        end

      {{:ok, %GroupUser{} = group_user}, _} ->
        {:ok, %{group: group, group_user: group_user}}

      {{:ok, nil}, _} ->
        {:ok, %{group: group, group_user: nil}}
    end
  end

  defp create_group_membership(group, space_user) do
    params = %{
      space_id: group.space_id,
      group_id: group.id,
      space_user_id: space_user.id,
      state: "SUBSCRIBED"
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

  defp delete_group_membership(group, space_user, group_user) do
    Multi.new()
    |> Multi.delete(:group_user, group_user)
    |> Multi.run(:unbookmarked, fn _ ->
      unbookmark_group(group, space_user)
      {:ok, true}
    end)
    |> Repo.transaction()
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
        Events.group_bookmarked(space_user.id, group)
        :ok

      {:error, %Changeset{errors: [uniqueness: _]}} ->
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
      Events.group_unbookmarked(space_user.id, group)
    end

    :ok
  end

  @doc """
  Lists all bookmarked groups.
  """
  @spec list_bookmarks(SpaceUser.t()) :: [Group.t()] | no_return()
  def list_bookmarks(space_user) do
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
  @spec close_group(Group.t()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def close_group(group) do
    group
    |> Changeset.change(state: "CLOSED")
    |> Repo.update()
  end

  @doc """
  Subscribes a user to a group.
  """
  @spec subscribe(Group.t(), SpaceUser.t()) :: :ok | {:error, Changeset.t()}
  def subscribe(%Group{} = group, %SpaceUser{} = space_user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        space_id: group.space_id,
        space_user_id: space_user.id,
        group_id: group.id,
        state: "SUBSCRIBED"
      })

    opts = [
      on_conflict: [set: [state: "SUBSCRIBED"]],
      conflict_target: [:space_user_id, :group_id]
    ]

    case Repo.insert(changeset, opts) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Unsubscribes a user from a group.
  """
  @spec unsubscribe(Group.t(), SpaceUser.t()) :: :ok | {:error, Changeset.t()}
  def unsubscribe(%Group{} = group, %SpaceUser{} = space_user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        space_id: group.space_id,
        space_user_id: space_user.id,
        group_id: group.id,
        state: "NOT_SUBSCRIBED"
      })

    opts = [
      on_conflict: [set: [state: "NOT_SUBSCRIBED"]],
      conflict_target: [:space_user_id, :group_id]
    ]

    case Repo.insert(changeset, opts) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Grants a user access to a group.
  """
  @spec grant_access(User.t(), Group.t(), SpaceUser.t()) :: :ok | {:error, String.t()}
  def grant_access(%User{} = current_user, %Group{} = group, %SpaceUser{} = space_user) do
    case get_user_role(group, current_user) do
      :owner ->
        changeset =
          Changeset.change(%GroupUser{}, %{
            space_id: group.space_id,
            space_user_id: space_user.id,
            group_id: group.id,
            state: "NOT_SUBSCRIBED"
          })

        case Repo.insert(changeset, on_conflict: :nothing) do
          {:ok, _} -> :ok
          _ -> {:error, dgettext("errors", "An unexpected error occurred.")}
        end

      _ ->
        {:error, dgettext("errors", "You are not authorized to perform this action.")}
    end
  end

  @doc """
  Revokes a user's access from a group.
  """
  @spec revoke_access(User.t(), Group.t(), SpaceUser.t()) :: :ok | {:error, String.t()}
  def revoke_access(%User{} = current_user, %Group{} = group, %SpaceUser{id: space_user_id}) do
    case get_user_role(group, current_user) do
      :owner ->
        group_id = group.id

        query =
          from gu in GroupUser,
            where: gu.space_user_id == ^space_user_id and gu.group_id == ^group_id

        {_count, _} = Repo.delete_all(query)
        :ok

      _ ->
        {:error, dgettext("errors", "You are not authorized to perform this action.")}
    end
  end

  @doc """
  Makes a user an owner of a group.
  """
  @spec set_owner_role(Group.t(), SpaceUser.t()) :: :ok | {:error, Changeset.t()}
  def set_owner_role(%Group{} = group, %SpaceUser{} = space_user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        space_id: group.space_id,
        space_user_id: space_user.id,
        group_id: group.id,
        role: "OWNER"
      })

    opts = [
      on_conflict: [set: [role: "OWNER"]],
      conflict_target: [:space_user_id, :group_id]
    ]

    case Repo.insert(changeset, opts) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Makes a user have a member role.
  """
  @spec set_member_role(Group.t(), SpaceUser.t()) :: :ok | {:error, Changeset.t()}
  def set_member_role(%Group{} = group, %SpaceUser{} = space_user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        space_id: group.space_id,
        space_user_id: space_user.id,
        group_id: group.id,
        role: "MEMBER"
      })

    opts = [
      on_conflict: [set: [role: "MEMBER"]],
      conflict_target: [:space_user_id, :group_id]
    ]

    case Repo.insert(changeset, opts) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Gets a user's state.
  """
  @spec get_user_state(Group.t(), User.t() | SpaceUser.t()) :: :not_subscribed | :subscribed | nil
  def get_user_state(%Group{} = group, user) do
    case get_group_user(group, user) do
      {:ok, %GroupUser{state: "SUBSCRIBED"}} -> :subscribed
      {:ok, %GroupUser{state: "NOT_SUBSCRIBED"}} -> :not_subscribed
      _ -> nil
    end
  end

  @doc """
  Gets a user's role.
  """
  @spec get_user_role(Group.t(), User.t() | SpaceUser.t()) :: :owner | :member | nil
  def get_user_role(%Group{} = group, user) do
    case get_group_user(group, user) do
      {:ok, %GroupUser{role: "OWNER"}} -> :owner
      {:ok, %GroupUser{role: "MEMBER"}} -> :member
      _ -> nil
    end
  end

  # Internal

  defp get_group_user(%Group{id: group_id}, %SpaceUser{id: space_user_id}) do
    GroupUser
    |> Repo.get_by(space_user_id: space_user_id, group_id: group_id)
    |> handle_get_group_user()
  end

  defp get_group_user(%Group{id: group_id}, %User{id: user_id}) do
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
end
