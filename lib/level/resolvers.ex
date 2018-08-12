defmodule Level.Resolvers do
  @moduledoc """
  Functions for loading connections between resources, designed to be used in
  GraphQL query resolution.
  """

  import Absinthe.Resolution.Helpers

  alias Level.Resolvers.GroupMembershipConnection
  alias Level.Resolvers.GroupPostConnection
  alias Level.Resolvers.GroupConnection
  alias Level.Resolvers.MentionConnection
  alias Level.Resolvers.ReplyConnection
  alias Level.Resolvers.SpaceUserConnection
  alias Level.Resolvers.UserGroupMembershipConnection
  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Groups.GroupBookmark
  alias Level.Groups.GroupUser
  alias Level.Mentions
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
  @spec space_users(User.t(), map(), info()) :: paginated_result()
  def space_users(%User{} = user, args, %{context: %{current_user: _user}} = info) do
    SpaceUserConnection.get(user, struct(SpaceUserConnection, args), info)
  end

  @spec space_users(Space.t(), map(), info()) :: paginated_result()
  def space_users(%Space{} = space, args, %{context: %{current_user: _user}} = info) do
    SpaceUserConnection.get(space, struct(SpaceUserConnection, args), info)
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
  @spec groups(Space.t(), map(), info()) :: paginated_result()
  def groups(%Space{} = space, args, %{context: %{current_user: _user}} = info) do
    GroupConnection.get(space, struct(GroupConnection, args), info)
  end

  @doc """
  Fetches group memberships.
  """
  @spec group_memberships(User.t(), map(), info()) :: paginated_result()
  def group_memberships(%User{} = user, args, %{context: %{current_user: _user}} = info) do
    UserGroupMembershipConnection.get(user, struct(UserGroupMembershipConnection, args), info)
  end

  @spec group_memberships(Group.t(), map(), info()) :: paginated_result()
  def group_memberships(%Group{} = user, args, %{context: %{current_user: _user}} = info) do
    GroupMembershipConnection.get(user, struct(GroupMembershipConnection, args), info)
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
  Fetches posts within a given group.
  """
  @spec group_posts(Group.t(), map(), info()) :: paginated_result()
  def group_posts(%Group{} = group, args, info) do
    GroupPostConnection.get(group, struct(GroupPostConnection, args), info)
  end

  @doc """
  Fetches replies to a given post.
  """
  @spec replies(Post.t(), map(), info()) :: paginated_result()
  def replies(%Post{} = post, args, info) do
    ReplyConnection.get(post, struct(ReplyConnection, args), info)
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
    MentionConnection.get(space, struct(MentionConnection, args), info)
  end

  @doc """
  Fetches the current user's membership.
  """
  @spec group_membership(Group.t(), map(), info()) :: {:middleware, any(), any()}
  def group_membership(%Group{} = group, _args, %{context: %{loader: loader}} = _info) do
    source_name = Level.Groups
    batch_key = {:one, GroupUser}
    item_key = [group_id: group.id]

    loader
    |> Dataloader.load(source_name, batch_key, item_key)
    |> on_load(fn loader ->
      loader
      |> Dataloader.get(source_name, batch_key, item_key)
      |> to_ok_tuple()
    end)
  end

  @doc """
  Fetches mentioners for a grouped user mention.
  """
  @spec mentioners(GroupedUserMention.t(), any(), info()) :: {:middleware, any(), any()}
  def mentioners(%GroupedUserMention{} = grouped_mention, _, %{context: %{loader: loader}}) do
    source_name = Spaces
    batch_key = SpaceUser
    item_keys = Mentions.mentioner_ids(grouped_mention)

    loader
    |> Dataloader.load_many(source_name, batch_key, item_keys)
    |> on_load(fn loader ->
      loader
      |> Dataloader.get_many(source_name, batch_key, item_keys)
      |> to_ok_tuple()
    end)
  end

  @doc """
  Fetches is bookmarked status for a group.
  """
  @spec is_bookmarked(Group.t(), any(), info()) :: {:middleware, any(), any()}
  def is_bookmarked(%Group{} = group, _, %{context: %{loader: loader}}) do
    source_name = Groups
    batch_key = {:one, GroupBookmark}
    item_key = [group_id: group.id]

    loader
    |> Dataloader.load(source_name, batch_key, item_key)
    |> on_load(fn loader ->
      loader
      |> Dataloader.get(source_name, batch_key, item_key)
      |> handle_bookmark_fetch()
    end)
  end

  defp handle_bookmark_fetch(%GroupBookmark{}), do: {:ok, true}
  defp handle_bookmark_fetch(_), do: {:ok, false}

  defp to_ok_tuple(value) do
    {:ok, value}
  end
end
