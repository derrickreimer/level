defmodule Level.Resolvers do
  @moduledoc """
  Functions for loading connections between resources, designed to be used in
  GraphQL query resolution.
  """

  import Absinthe.Resolution.Helpers

  alias Level.Resolvers.GroupMemberships
  alias Level.Resolvers.GroupPosts
  alias Level.Resolvers.Groups
  alias Level.Resolvers.Mentions
  alias Level.Resolvers.Replies
  alias Level.Resolvers.SpaceUsers
  alias Level.Resolvers.UserGroupMemberships
  alias Level.Groups.Group
  alias Level.Groups.GroupUser
  alias Level.Mentions.GroupedUserMention
  alias Level.Pagination
  alias Level.Posts.Post
  alias Level.Spaces
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  @typedoc "A info map for Absinthe GraphQL"
  @type info :: %{context: %{current_user: User.t(), loader: Dataloader.t()}}

  @typedoc "The return value for paginated connections"
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}

  @doc """
  Fetches a space by id.
  """
  @spec space(map(), info()) :: {:ok, Space.t()} | {:error, String.t()}
  def space(%{id: id} = _args, %{context: %{current_user: user}} = _info) do
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
  @spec space_user(map(), info()) :: {:ok, SpaceUser.t()} | {:error, String.t()}
  def space_user(%{space_id: id} = _args, %{context: %{current_user: user}} = _info) do
    case Spaces.get_space(user, id) do
      {:ok, %{space_user: space_user}} ->
        {:ok, space_user}

      error ->
        error
    end
  end

  @doc """
  Fetches a group by id.
  """
  @spec group(map(), info()) :: {:ok, Group.t()} | {:error, String.t()}
  def group(%{id: id} = _args, %{context: %{current_user: user}}) do
    Level.Groups.get_group(user, id)
  end

  @doc """
  Fetches space users belonging to a given user or a given space.
  """
  @spec space_users(User.t(), SpaceUsers.t(), info()) :: paginated_result()
  @spec space_users(Space.t(), SpaceUsers.t(), info()) :: paginated_result()

  def space_users(%User{} = user, args, %{context: %{current_user: _user}} = info) do
    SpaceUsers.get(user, struct(SpaceUsers, args), info)
  end

  def space_users(%Space{} = space, args, %{context: %{current_user: _user}} = info) do
    SpaceUsers.get(space, struct(SpaceUsers, args), info)
  end

  @doc """
  Fetches featured group memberships.
  """
  @spec featured_space_users(Space.t(), map(), info()) :: {:ok, [SpaceUser.t()]} | no_return()
  def featured_space_users(%Space{} = space, _args, %{context: %{current_user: _user}} = _info) do
    Level.Spaces.list_featured_users(space)
  end

  @doc """
  Fetches groups for given a space that are visible to the current user.
  """
  @spec groups(Space.t(), Groups.t(), info()) :: paginated_result()
  def groups(%Space{} = space, args, %{context: %{current_user: _user}} = info) do
    Groups.get(space, struct(Groups, args), info)
  end

  @doc """
  Fetches group memberships.
  """
  @spec group_memberships(User.t(), UserGroupMemberships.t(), info()) :: paginated_result()
  @spec group_memberships(Group.t(), GroupMemberships.t(), info()) :: paginated_result()

  def group_memberships(%User{} = user, args, %{context: %{current_user: _user}} = info) do
    UserGroupMemberships.get(user, struct(UserGroupMemberships, args), info)
  end

  def group_memberships(%Group{} = user, args, %{context: %{current_user: _user}} = info) do
    GroupMemberships.get(user, struct(GroupMemberships, args), info)
  end

  @doc """
  Fetches featured group memberships.
  """
  @spec featured_group_memberships(Group.t(), map(), info()) ::
          {:ok, [GroupUser.t()]} | no_return()
  def featured_group_memberships(group, _args, _info) do
    Level.Groups.list_featured_memberships(group)
  end

  @doc """
  Fetches the current user's membership.
  """
  @spec group_membership(Group.t(), map(), info()) :: {:ok, GroupUser.t() | nil}
  def group_membership(%Group{} = group, _args, %{context: %{current_user: user}} = _info) do
    Level.Groups.get_group_user(group, user)
  end

  @doc """
  Fetches posts within a given group.
  """
  @spec group_posts(Group.t(), GroupPosts.t(), info()) :: paginated_result()
  def group_posts(%Group{} = group, args, info) do
    GroupPosts.get(group, struct(GroupPosts, args), info)
  end

  @doc """
  Fetches replies to a given post.
  """
  @spec replies(Post.t(), Replies.t(), info()) :: paginated_result()
  def replies(%Post{} = post, args, info) do
    Replies.get(post, struct(Replies, args), info)
  end

  @doc """
  Fetches a post by id.
  """
  @spec post(Space.t(), map(), info()) :: {:ok, Post.t()} | {:error, String.t()}
  def post(%Space{} = space, %{id: id} = _args, %{context: %{current_user: user}} = _info) do
    with {:ok, %{space_user: space_user}} <- Spaces.get_space(user, space.id),
         {:ok, post} <- Level.Posts.get_post(space_user, id) do
      {:ok, post}
    else
      error ->
        error
    end
  end

  @doc """
  Fetches mentions for the current user by space id.
  """
  @spec mentions(Space.t(), map(), info()) :: paginated_result()
  def mentions(%Space{} = space, args, info) do
    Mentions.get(space, struct(Mentions, args), info)
  end

  @doc """
  Fetches mentioners for a grouped user mention.
  """
  @spec mentioners(GroupedUserMention.t(), any(), info()) :: {:middleware, any(), any()}
  def mentioners(%GroupedUserMention{} = grouped_mention, _, %{context: %{loader: loader}}) do
    ids = Level.Mentions.mentioner_ids(grouped_mention)

    loader
    |> Dataloader.load_many(Spaces, SpaceUser, ids)
    |> on_load(fn loader ->
      result = Dataloader.get_many(loader, Spaces, SpaceUser, ids)
      {:ok, result}
    end)
  end
end
