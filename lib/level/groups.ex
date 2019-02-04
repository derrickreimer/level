defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Changeset, only: [change: 2, unique_constraint: 3]
  import Ecto.Query, warn: false
  import Level.Gettext

  alias Ecto.Changeset
  alias Level.Events
  alias Level.Repo
  alias Level.Schemas.Group
  alias Level.Schemas.GroupBookmark
  alias Level.Schemas.GroupUser
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  @doc """
  Generate the query for listing all accessible groups.
  """
  @spec groups_base_query(SpaceUser.t()) :: Ecto.Query.t()
  @spec groups_base_query(SpaceBot.t()) :: Ecto.Query.t()
  @spec groups_base_query(User.t()) :: Ecto.Query.t()

  def groups_base_query(%SpaceUser{id: space_user_id, space_id: space_id}) do
    from g in Group,
      where: g.space_id == ^space_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id and gu.space_user_id == ^space_user_id,
      where: g.is_private == false or (g.is_private == true and gu.access == "PRIVATE"),
      where: g.state != "DELETED"
  end

  def groups_base_query(%SpaceBot{space_id: space_id}) do
    from g in Group,
      where: g.space_id == ^space_id,
      where: g.is_private == false,
      where: g.state != "DELETED"
  end

  def groups_base_query(%User{id: user_id}) do
    from g in Group,
      join: su in SpaceUser,
      on: su.space_id == g.space_id and su.user_id == ^user_id,
      left_join: gu in GroupUser,
      on: gu.group_id == g.id and gu.space_user_id == su.id,
      where: g.is_private == false or (g.is_private == true and gu.access == "PRIVATE"),
      where: g.state != "DELETED"
  end

  @doc """
  Generate the query for all members.
  """
  @spec members_base_query(Group.t()) :: Ecto.Query.t()
  def members_base_query(%Group{id: group_id}) do
    from gu in GroupUser,
      join: su in assoc(gu, :space_user),
      where: su.state == "ACTIVE",
      where: gu.group_id == ^group_id,
      where: gu.state in ["SUBSCRIBED", "WATCHING"],
      join: u in assoc(gu, :user),
      select: %{gu | last_name: u.last_name}
  end

  @doc """
  Fetches a group by id.
  """
  @spec get_group(SpaceUser.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group(%SpaceUser{} = member, id) do
    case Repo.get_by(groups_base_query(member), id: id) do
      %Group{} = group ->
        {:ok, group}

      _ ->
        {:error, dgettext("errors", "Group not found")}
    end
  end

  @spec get_group(User.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group(%User{} = user, id) do
    case Repo.get_by(groups_base_query(user), id: id) do
      %Group{} = group ->
        {:ok, group}

      _ ->
        {:error, dgettext("errors", "Group not found")}
    end
  end

  @doc """
  Fetches a group by name.
  """
  @spec get_group_by_name(User.t(), String.t(), String.t()) ::
          {:ok, Group.t()} | {:error, String.t()}
  def get_group_by_name(%User{} = user, space_slug, name) do
    query =
      from [g, su, gu] in groups_base_query(user),
        join: s in Space,
        on: g.space_id == s.id,
        where: s.slug == ^space_slug,
        where: g.name == ^name

    case Repo.one(query) do
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

  Currently returns the top users, ordered alphabetically.
  """
  @spec list_featured_memberships(Group.t()) :: {:ok, [GroupUser.t()]} | no_return()
  def list_featured_memberships(group) do
    base_query = members_base_query(group)

    query =
      from gu in subquery(base_query),
        order_by: {:asc, gu.last_name},
        limit: 20

    {:ok, Repo.all(query)}
  end

  @doc """
  Lists all members of a group.
  """
  @spec list_all_memberships(Group.t()) :: {:ok, [GroupUser.t()]} | no_return()
  def list_all_memberships(group) do
    base_query = members_base_query(group)
    query = from gu in subquery(base_query), order_by: {:asc, gu.last_name}
    {:ok, Repo.all(query)}
  end

  @doc """
  Lists group watchers.
  """
  @spec list_all_watchers(Group.t()) :: {:ok, [GroupUser.t()]} | no_return()
  def list_all_watchers(group) do
    base_query = members_base_query(group)

    query =
      from gu in subquery(base_query),
        where: gu.state == "WATCHING",
        order_by: {:asc, gu.last_name}

    {:ok, Repo.all(query)}
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
  Reopens a group.
  """
  @spec reopen_group(Group.t()) :: {:ok, Group.t()} | {:error, Changeset.t()}
  def reopen_group(group) do
    group
    |> Changeset.change(state: "OPEN")
    |> Repo.update()
  end

  @doc """
  Deletes a group.
  """
  @spec delete_group(SpaceUser.t(), Group.t()) ::
          {:ok, Group.t()} | {:error, Changeset.t() | String.t()}
  def delete_group(current_user, group) do
    case get_user_role(group, current_user) do
      :owner ->
        group
        |> Changeset.change(state: "DELETED")
        |> Repo.update()

      _ ->
        {:error, dgettext("errors", "You are not authorized to perform this action.")}
    end
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
        state: "SUBSCRIBED",
        access: "PRIVATE"
      })

    opts = [
      on_conflict: [set: [state: "SUBSCRIBED", access: "PRIVATE"]],
      conflict_target: [:space_user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_subscribe(group, space_user)
  end

  defp after_subscribe({:ok, _}, group, space_user) do
    bookmark_group(group, space_user)
    Events.subscribed_to_group(group.id, group, space_user)
    :ok
  end

  defp after_subscribe(err, _, _) do
    err
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

    changeset
    |> Repo.insert(opts)
    |> after_unsubscribe(group, space_user)
  end

  defp after_unsubscribe({:ok, _}, group, space_user) do
    unbookmark_group(group, space_user)
    Events.unsubscribed_from_group(group.id, group, space_user)
    :ok
  end

  defp after_unsubscribe(err, _, _) do
    err
  end

  @doc """
  Watches a group.
  """
  @spec watch(Group.t(), SpaceUser.t()) :: :ok | {:error, Changeset.t()}
  def watch(%Group{} = group, %SpaceUser{} = space_user) do
    changeset =
      Changeset.change(%GroupUser{}, %{
        space_id: group.space_id,
        space_user_id: space_user.id,
        group_id: group.id,
        state: "WATCHING"
      })

    opts = [
      on_conflict: [set: [state: "WATCHING"]],
      conflict_target: [:space_user_id, :group_id]
    ]

    changeset
    |> Repo.insert(opts)
    |> after_watch(group, space_user)
  end

  defp after_watch({:ok, _}, group, space_user) do
    Events.watched_group(group.id, group, space_user)
    :ok
  end

  defp after_watch(err, _, _) do
    err
  end

  @doc """
  Grants a user access to a private group.
  """
  @spec grant_private_group_access(User.t(), Group.t(), SpaceUser.t()) ::
          :ok | {:error, String.t()}
  def grant_private_group_access(%User{} = current_user, %Group{} = group, space_user) do
    case get_user_role(group, current_user) do
      :owner ->
        changeset =
          Changeset.change(%GroupUser{}, %{
            space_id: group.space_id,
            space_user_id: space_user.id,
            group_id: group.id,
            access: "PRIVATE"
          })

        opts = [
          on_conflict: [set: [access: "PRIVATE"]],
          conflict_target: [:space_user_id, :group_id]
        ]

        case Repo.insert(changeset, opts) do
          {:ok, _} -> :ok
          _ -> {:error, dgettext("errors", "An unexpected error occurred.")}
        end

      _ ->
        {:error, dgettext("errors", "You are not authorized to perform this action.")}
    end
  end

  @doc """
  Revokes a user's access from a private group.
  """
  @spec revoke_private_group_access(User.t(), Group.t(), SpaceUser.t()) ::
          :ok | {:error, String.t()}
  def revoke_private_group_access(%User{} = current_user, %Group{} = group, space_user) do
    case get_user_role(group, current_user) do
      :owner ->
        changeset =
          Changeset.change(%GroupUser{}, %{
            space_id: group.space_id,
            space_user_id: space_user.id,
            group_id: group.id,
            access: "PUBLIC",
            state: "NOT_SUBSCRIBED"
          })

        opts = [
          on_conflict: [set: [access: "PUBLIC", state: "NOT_SUBSCRIBED"]],
          conflict_target: [:space_user_id, :group_id]
        ]

        case Repo.insert(changeset, opts) do
          {:ok, _} -> :ok
          _ -> {:error, dgettext("errors", "An unexpected error occurred.")}
        end

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
  @spec get_user_state(Group.t(), User.t() | SpaceUser.t()) ::
          :not_subscribed | :subscribed | :watching | nil
  def get_user_state(%Group{} = group, user) do
    case get_group_user(group, user) do
      {:ok, %GroupUser{state: "SUBSCRIBED"}} -> :subscribed
      {:ok, %GroupUser{state: "NOT_SUBSCRIBED"}} -> :not_subscribed
      {:ok, %GroupUser{state: "WATCHING"}} -> :watching
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

  @doc """
  Gets a user's access.
  """
  @spec get_user_access(Group.t(), User.t() | SpaceUser.t()) :: :private | :public | nil
  def get_user_access(%Group{} = group, user) do
    case get_group_user(group, user) do
      {:ok, %GroupUser{access: "PRIVATE"}} -> :private
      {:ok, %GroupUser{access: "PUBLIC"}} -> :public
      _ -> nil
    end
  end

  @doc """
  Determines if a user is allowed to privatize a group.
  """
  @spec can_privatize?(GroupUser.t() | nil) :: {:ok, boolean()}
  def can_privatize?(%GroupUser{} = group_user) do
    {:ok, group_user.access == "PRIVATE"}
  end

  def can_privatize?(nil), do: {:ok, false}

  @doc """
  Determines if a user is allowed to publicize a group.
  """
  @spec can_publicize?(GroupUser.t() | nil) :: {:ok, boolean()}
  def can_publicize?(%GroupUser{} = group_user) do
    {:ok, group_user.access == "PRIVATE"}
  end

  def can_publicize?(nil), do: {:ok, false}

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
