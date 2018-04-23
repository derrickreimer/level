defmodule Level.Connections do
  @moduledoc """
  Functions for loading connections between resources, designed to be used in
  GraphQL query resolution.
  """

  alias Level.Connections.GroupMemberships
  alias Level.Connections.Groups
  alias Level.Connections.SpaceMemberships
  alias Level.Connections.Users
  alias Level.Pagination
  alias Level.Spaces
  alias Level.Spaces.Space
  alias Level.Users.User

  @typedoc "A context map containing the current user"
  @type authenticated_context :: %{context: %{current_user: User.t()}}

  @typedoc "The return value for paginated connections"
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}

  @doc """
  Fetches a space by id.
  """
  @spec space(User.t(), map(), authenticated_context()) :: {:ok, Space.t()} | {:error, String.t()}
  def space(_parent, %{id: id} = args, %{context: %{current_user: authenticated_user}} = context) do
    case Spaces.get_space(authenticated_user, id) do
      {:ok, %{space: space}} ->
        {:ok, space}

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
