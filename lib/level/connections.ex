defmodule Level.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  @doc """
  Fetch users belonging to a space.

  ## Examples

      users(space, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%User{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}

      users(space, invalid_args)
      => {:error, "You cannot provide both a `before` and `after` value"}

  """
  def users(space, args, context \\ %{}) do
    Level.Connections.Users.get(space, args, context)
  end

  @doc """
  Fetch pending invitations for given a space.

  ## Examples

      invitations(space, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%Invitation{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}

      invitations(space, invalid_args)
      => {:error, "You cannot provide both a `before` and `after` value"}

  """
  def invitations(space, args, context \\ %{}) do
    Level.Connections.Invitations.get(space, args, context)
  end

  @doc """
  Fetch groups for given a space.

  ## Examples

      groups(space, args)
      => {:ok, %Level.Pagination.Result{
        edges: [%Group{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}

      groups(space, invalid_args)
      => {:error, "You cannot provide both a `before` and `after` value"}

  """
  def groups(space, args, context \\ %{}) do
    Level.Connections.Groups.get(space, args, context)
  end

  @doc """
  Fetch group memberships for a given user.
  """
  def group_memberships(user, args, context \\ %{}) do
    Level.Connections.GroupMemberships.get(user, args, context)
  end
end
