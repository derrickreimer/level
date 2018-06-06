defmodule Level.Connections do
  @moduledoc """
  Functions for loading connections between resources, designed to be used in
  GraphQL query resolution.
  """

  alias Level.Connections.GroupMemberships
  alias Level.Connections.GroupPosts
  alias Level.Connections.Groups
  alias Level.Connections.SpaceUsers
  alias Level.Connections.UserGroupMemberships
  alias Level.Groups.Group
  alias Level.Groups.GroupUser
  alias Level.Pagination
  alias Level.Spaces
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  @typedoc "A context map containing the current user"
  @type authenticated_context :: %{context: %{current_user: User.t()}}

  @typedoc "The return value for paginated connections"
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}

  @doc """
  Fetches a space by id.
  """
  @spec space(term(), map(), authenticated_context()) :: {:ok, Space.t()} | {:error, String.t()}
  def space(parent, args, info)

  def space(_root, %{id: id}, %{context: %{current_user: user}}) do
    case Spaces.get_space(user, id) do
      {:ok, %{space: space}} ->
        {:ok, space}

      error ->
        error
    end
  end

  @doc """
  Fetches a space membership by space id.
  """
  @spec space_user(User.t(), map(), authenticated_context()) ::
          {:ok, SpaceUser.t()} | {:error, String.t()}
  def space_user(parent, args, info)

  def space_user(_parent, %{space_id: id}, %{context: %{current_user: user}}) do
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
  @spec space_users(User.t(), SpaceUsers.t(), authenticated_context()) :: paginated_result()
  def space_users(user, args, info) do
    SpaceUsers.get(user, struct(SpaceUsers, args), info)
  end

  @doc """
  Fetches groups for given a space that are visible to the current user.
  """
  @spec groups(Space.t(), Groups.t(), authenticated_context()) :: paginated_result()
  def groups(space, args, info) do
    Groups.get(space, struct(Groups, args), info)
  end

  @doc """
  Fetches a group by id.
  """
  @spec group(Space.t(), map(), authenticated_context()) ::
          {:ok, Group.t()} | {:error, String.t()}
  def group(space, %{id: id} = _args, %{context: %{current_user: user}}) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space.id),
         {:ok, group} <- Level.Groups.get_group(space_user, id) do
      {:ok, group}
    else
      error ->
        error
    end
  end

  @doc """
  Fetches group memberships.
  """
  @spec group_memberships(User.t(), UserGroupMemberships.t(), authenticated_context()) ::
          paginated_result()
  @spec group_memberships(Group.t(), GroupMemberships.t(), authenticated_context()) ::
          paginated_result()

  def group_memberships(%User{} = user, args, info) do
    UserGroupMemberships.get(user, struct(UserGroupMemberships, args), info)
  end

  def group_memberships(%Group{} = user, args, info) do
    GroupMemberships.get(user, struct(GroupMemberships, args), info)
  end

  @doc """
  Fetches featured group memberships.
  """
  @spec featured_group_memberships(Group.t(), map(), authenticated_context) ::
          {:ok, [GroupUser.t()]} | no_return()
  def featured_group_memberships(group, _args, _info) do
    Level.Groups.list_featured_memberships(group)
  end

  @doc """
  Fetches the current user's membership.
  """
  @spec group_membership(Group.t(), map(), authenticated_context()) ::
          {:ok, GroupUser.t()} | {:error, String.t()}
  def group_membership(%Group{} = group, _args, %{context: %{current_user: user}}) do
    case Spaces.get_space(user, group.space_id) do
      {:ok, %{space_user: space_user, space: space}} ->
        case Level.Groups.get_group_membership(group, space_user) do
          {:ok, group_user} ->
            {:ok, group_user}

          _ ->
            virtual_group_user = %GroupUser{
              state: "NOT_SUBSCRIBED",
              space: space,
              group: group,
              space_user: space_user
            }

            {:ok, virtual_group_user}
        end

      error ->
        error
    end
  end

  @doc """
  Fetches posts within a given group.
  """
  @spec group_posts(Group.t(), GroupPosts.t(), authenticated_context()) :: paginated_result()
  def group_posts(group, args, info) do
    GroupPosts.get(group, struct(GroupPosts, args), info)
  end
end
