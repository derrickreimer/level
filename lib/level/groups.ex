defmodule Level.Groups do
  @moduledoc """
  The Groups context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Level.Repo
  alias Level.Groups.Group
  alias Level.Groups.GroupMembership

  @doc """
  Creates a group.

  ## Examples

      # Returns the newly created group and membership if successful.
      create_group(%User{}, %{name: value})
      => {:ok, %{group: %Group{}, membership: %GroupMembership{}}}

      # Otherwise, returns an error.
      => {:error, failed_operation, failed_value, changes_so_far}

  """
  def create_group(creator, params \\ %{}) do
    params_with_relations =
      params
      |> Map.put(:space_id, creator.space_id)
      |> Map.put(:creator_id, creator.id)

    changeset = Group.changeset(%Group{}, params_with_relations)

    Multi.new()
    |> Multi.insert(:group, changeset)
    |> Multi.run(:membership, fn %{group: group} ->
      create_group_membership(group, creator)
    end)
    |> Repo.transaction()
  end

  @doc """
  Creates a group membership.

  ## Examples

      # Returns the newly created group membership if successful.
      create_group_membership(%Group{}, %User{})
      => {:ok, %GroupMembership{}}

      # Otherwise, returns an error changeset.
      => {:error, %Ecto.Changeset{}}

  """
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

  ## Examples

      iex> close_group(%Group{state: "OPEN"})
      {:ok, %Group{state: "CLOSED"}}

      iex> close_group(%Group{})
      {:error, %Ecto.Changeset{}}

  """
  def close_group(group) do
    group
    |> Ecto.Changeset.change(state: "CLOSED")
    |> Repo.update()
  end
end
