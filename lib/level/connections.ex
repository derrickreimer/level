defmodule Level.Connections do
  @moduledoc """
  Functions for loading connections between resources, designed to be used in GraphQL query resolution.
  """

  alias Level.Pagination
  alias Level.Spaces.Space
  alias Level.Spaces.User

  @typedoc "A context map containing the current user"
  @type authenticated_context :: %{context: %{current_user: User.t()}}

  @typedoc "The return value for connections"
  @type result :: {:ok, Pagination.Result.t()} | {:error, String.t()}

  @doc """
  Fetch users belonging to a space.
  """
  @spec users(Space.t(), map(), authenticated_context()) :: result()
  def users(space, args, %{context: %{current_user: _}} = context) do
    Level.Connections.Users.get(space, args, context)
  end

  @doc """
  Fetch pending invitations for given a space.
  """
  @spec invitations(Space.t(), map(), authenticated_context()) :: result()
  def invitations(space, args, %{context: %{current_user: _}} = context) do
    Level.Connections.Invitations.get(space, args, context)
  end

  @doc """
  Fetch groups for given a space that are visible to the current user.
  """
  @spec groups(Space.t(), map(), authenticated_context()) :: result()
  def groups(space, args, %{context: %{current_user: _}} = context) do
    Level.Connections.Groups.get(space, args, context)
  end

  @doc """
  Fetch group memberships for a given user.
  """
  @spec group_memberships(User.t(), map(), authenticated_context()) :: result()
  def group_memberships(user, args, %{context: %{current_user: _}} = context) do
    Level.Connections.GroupMemberships.get(user, args, context)
  end
end
