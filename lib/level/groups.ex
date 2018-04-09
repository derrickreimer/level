defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Level.Repo
  alias Level.Spaces.User
  alias Level.Groups.Group
  alias Level.Groups.GroupMembership

  @doc """
  Fetch a group by id.
  """
  @spec find_group(String.t()) :: {:ok, Group.t()} | {:error, String.t()}
  def find_group(id) do
    case Repo.get(Group, id) do
      %Group{} = group ->
        {:ok, group}

      _ ->
        {:error, "Group not found"}
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
