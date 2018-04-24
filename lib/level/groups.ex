defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Repo
  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Spaces

  @doc """
  Generate the query for listing all groups visible to a given member.
  """
  @spec list_groups_query(Spaces.Member.t()) :: Ecto.Query.t()
  def list_groups_query(%Spaces.Member{id: member_id, space_id: space_id}) do
    from g in Group,
      where: g.space_id == ^space_id,
      left_join: gm in Groups.Member,
      on: gm.group_id == g.id and gm.space_member_id == ^member_id,
      where: g.is_private == false or (g.is_private == true and not is_nil(gm.id))
  end

  @doc """
  Fetches a group by id.
  """
  @spec get_group(Spaces.Member.t(), String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def get_group(%Spaces.Member{space_id: space_id} = member, id) do
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
  @spec create_group(Spaces.Member.t(), map()) ::
          {:ok, %{group: Group.t(), member: Groups.Member.t()}}
          | {:error, :group | :member, any(), %{optional(:group | :member) => any()}}
  def create_group(member, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, member.space_id)
      |> Map.put(:creator_id, member.id)

    changeset = Group.create_changeset(%Group{}, params_with_relations)

    Multi.new()
    |> Multi.insert(:group, changeset)
    |> Multi.run(:member, fn %{group: group} ->
      create_group_membership(group, member)
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
  @spec get_group_membership(Group.t(), Spaces.Member.t()) ::
          {:ok, Groups.Member.t()} | {:error, String.t()}
  def get_group_membership(%Group{id: group_id}, %Spaces.Member{id: member_id}) do
    case Repo.get_by(Groups.Member, space_member_id: member_id, group_id: group_id) do
      %Groups.Member{} = membership ->
        {:ok, membership}

      _ ->
        {:error, dgettext("errors", "The user is a not a group member")}
    end
  end

  @doc """
  Creates a group membership.
  """
  @spec create_group_membership(Group.t(), Spaces.Member.t()) ::
          {:ok, Groups.Member.t()} | {:error, Ecto.Changeset.t()}
  def create_group_membership(group, member) do
    params = %{
      space_id: member.space_id,
      group_id: group.id,
      space_member_id: member.id
    }

    %Groups.Member{}
    |> Groups.Member.changeset(params)
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
