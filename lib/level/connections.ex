defmodule Level.Connections do
  @moduledoc """
  Functions for loading connections between resources, designed to be used in GraphQL query resolution.
  """

  alias Level.Connections.Invitations
  alias Level.Connections.GroupMemberships
  alias Level.Connections.Groups
  alias Level.Connections.Users
  alias Level.Pagination
  alias Level.Spaces.Space
  alias Level.Spaces.User

  @typedoc "A context map containing the current user"
  @type authenticated_context :: %{context: %{current_user: User.t()}}

  @typedoc "The return value for connections"
  @type result :: {:ok, Pagination.Result.t()} | {:error, String.t()}

  @doc """
  Fetches users belonging to a space.
  """
  @spec users(Space.t(), Users.t(), authenticated_context()) :: result()
  def users(space, args, %{context: %{current_user: _}} = context) do
    Users.get(space, struct(Users, args), context)
  end

  @doc """
  Fetches pending invitations for given a space.
  """
  @spec invitations(Space.t(), Invitations.t(), authenticated_context()) :: result()
  def invitations(space, args, %{context: %{current_user: _}} = context) do
    Invitations.get(space, struct(Invitations, args), context)
  end

  @doc """
  Fetches groups for given a space that are visible to the current user.
  """
  @spec groups(Space.t(), Groups.t(), authenticated_context()) :: result()
  def groups(space, args, %{context: %{current_user: _}} = context) do
    Groups.get(space, struct(Groups, args), context)
  end

  @doc """
  Fetches group memberships for a given user.
  """
  @spec group_memberships(User.t(), GroupMemberships.t(), authenticated_context()) :: result()
  def group_memberships(user, args, %{context: %{current_user: _}} = context) do
    GroupMemberships.get(user, struct(GroupMemberships, args), context)
  end
end
