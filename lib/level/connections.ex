defmodule Level.Connections do
  @moduledoc """
  A context for exposing connections between nodes.
  """

  alias Level.Pagination
  alias Level.Spaces.Space
  alias Level.Spaces.User

  @doc """
  Fetch users belonging to a space.
  """
  @spec users(Space.t(), map(), map()) :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  def users(space, args, context \\ %{}) do
    Level.Connections.Users.get(space, args, context)
  end

  @doc """
  Fetch pending invitations for given a space.
  """
  @spec invitations(Space.t(), map(), map()) ::
          {:ok, Pagination.Result.t()} | {:error, String.t()}
  def invitations(space, args, context \\ %{}) do
    Level.Connections.Invitations.get(space, args, context)
  end

  @doc """
  Fetch groups for given a space.
  """
  @spec groups(Space.t(), map(), %{context: %{current_user: User.t()}}) ::
          {:ok, Pagination.Result.t()} | {:error, String.t()}
  def groups(space, args, %{context: %{current_user: _}} = context) do
    Level.Connections.Groups.get(space, args, context)
  end

  @doc """
  Fetch group memberships for a given user.
  """
  @spec group_memberships(User.t(), map(), map()) ::
          {:ok, Pagination.Result.t()} | {:error, String.t()}
  def group_memberships(user, args, context \\ %{}) do
    Level.Connections.GroupMemberships.get(user, args, context)
  end
end
