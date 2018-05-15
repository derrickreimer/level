defmodule Level.Connections do
  @moduledoc """
  Functions for loading connections between resources, designed to be used in
  GraphQL query resolution.
  """

  alias Level.Connections.GroupMemberships
  alias Level.Connections.Groups
  alias Level.Connections.SpaceMemberships
  alias Level.Pagination
  alias Level.Spaces
  alias Level.Spaces.Space
  alias Level.Users.User

  @typedoc "A context map containing the current user"
  @type authenticated_context :: %{context: %{current_user: User.t()}}

  @typedoc "The return value for paginated connections"
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}

  @doc """
  Fetches a space membership by space id.
  """
  @spec space_membership(User.t(), map(), authenticated_context()) ::
          {:ok, SpaceUser.t()} | {:error, String.t()}
  def space_membership(parent, args, context)

  def space_membership(_parent, %{space_id: id}, %{context: %{current_user: user}}) do
    case Spaces.get_space(user, id) do
      {:ok, %{space_user: space_user}} ->
        {:ok, space_user}

      error ->
        error
    end
  end

  @doc """
  Fetches spaces that a user belongs to.
  """
  @spec space_memberships(User.t(), SpaceMemberships.t(), authenticated_context()) ::
          paginated_result()
  def space_memberships(user, args, context) do
    SpaceMemberships.get(user, struct(SpaceMemberships, args), context)
  end

  @doc """
  Fetches groups for given a space that are visible to the current user.
  """
  @spec groups(Space.t(), Groups.t(), authenticated_context()) :: paginated_result()
  def groups(space, args, context) do
    Groups.get(space, struct(Groups, args), context)
  end

  @doc """
  Fetches group memberships for a given user.
  """
  @spec group_memberships(User.t(), GroupMemberships.t(), authenticated_context()) ::
          paginated_result()
  def group_memberships(user, args, context) do
    GroupMemberships.get(user, struct(GroupMemberships, args), context)
  end
end
