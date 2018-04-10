defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Repo
  alias Level.Spaces.User
  alias Level.Groups.Group
  alias Level.Groups.GroupMembership

  @doc """
  Generate the query for listing all groups visible to a given user.
  """
  @spec list_groups_query(User.t()) :: Ecto.Query.t()
  def list_groups_query(%User{id: user_id, space_id: space_id}) do
    from g in Group,
      where: g.space_id == ^space_id,
      left_join: gm in GroupMembership,
      on: gm.user_id == ^user_id,
      where: g.is_private == false or (g.is_private == true and not is_nil(gm.id))
  end

  @doc """
  Fetches a group by id.
  """
  @spec get_group(User.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group(%User{space_id: space_id} = user, id) do
    case Repo.get_by(Group, id: id, space_id: space_id) do
      %Group{} = group ->
        if group.is_private do
          case get_group_membership(group, user) do
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
  @spec create_group(User.t(), map()) ::
          {:ok, %{group: Group.t(), membership: GroupMembership.t()}}
          | {:error, :group | :membership, any(), %{optional(:group | :membership) => any()}}
  def create_group(creator, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, creator.space_id)
      |> Map.put(:creator_id, creator.id)

    changeset = Group.create_changeset(%Group{}, params_with_relations)

    Multi.new()
    |> Multi.insert(:group, changeset)
    |> Multi.run(:membership, fn %{group: group} ->
      create_group_membership(group, creator)
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
  @spec get_group_membership(Group.t(), User.t()) ::
          {:ok, GroupMembership.t()} | {:error, String.t()}
  def get_group_membership(%Group{id: group_id}, %User{id: user_id}) do
    case Repo.get_by(GroupMembership, user_id: user_id, group_id: group_id) do
      %GroupMembership{} = membership ->
        {:ok, membership}

      _ ->
        {:error, dgettext("errors", "The user is a not a group member")}
    end
  end

  @doc """
  Creates a group membership.
  """
  @spec create_group_membership(Group.t(), User.t()) ::
          {:ok, GroupMembership.t()} | {:error, Ecto.Changeset.t()}
  def create_group_membership(group, user) do
    params = %{
      space_id: user.space_id,
      group_id: group.id,
      user_id: user.id
    }

    %GroupMembership{}
    |> GroupMembership.changeset(params)
    |> Repo.insert()
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
