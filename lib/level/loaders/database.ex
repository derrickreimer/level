defmodule Level.Loaders.Database do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Groups.GroupBookmark
  alias Level.Groups.GroupUser
  alias Level.Mentions
  alias Level.Mentions.UserMention
  alias Level.Posts
  alias Level.Posts.Post
  alias Level.Posts.PostUser
  alias Level.Posts.Reply
  alias Level.Posts.ReplyView
  alias Level.Repo
  alias Level.Spaces
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  # Suppress dialyzer warnings about dataloader functions
  @dialyzer {:nowarn_function, source: 1}

  def source(%{current_user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)
  end

  def source(_), do: raise("authentication required")

  # Spaces

  def query(Space, %{current_user: user}), do: Spaces.spaces_base_query(user)
  def query(SpaceUser, %{current_user: user}), do: Spaces.space_users_base_query(user)

  # Groups

  def query(Group, %{current_user: user}) do
    Groups.groups_base_query(user)
  end

  def query(GroupBookmark, %{current_user: %User{id: user_id}}) do
    from b in GroupBookmark,
      join: su in assoc(b, :space_user),
      where: su.user_id == ^user_id
  end

  def query(GroupUser, %{current_user: %User{id: user_id}}) do
    from gu in GroupUser,
      join: su in assoc(gu, :space_user),
      where: su.user_id == ^user_id
  end

  # Posts

  def query(Post, %{current_user: user}), do: Posts.posts_base_query(user)

  def query(PostUser, %{current_user: %User{id: user_id}}) do
    from pu in PostUser,
      join: su in assoc(pu, :space_user),
      where: su.user_id == ^user_id
  end

  # Replies

  def query(Reply, %{current_user: user}), do: Posts.replies_base_query(user)

  def query(ReplyView, %{current_user: %User{id: user_id}}) do
    from rv in ReplyView,
      join: su in assoc(rv, :space_user),
      where: su.user_id == ^user_id
  end

  # Mentions

  def query(UserMention, %{current_user: user}), do: Mentions.base_query(user)

  # Fallback

  def query(batch_key, _params) do
    raise("query for " <> to_string(batch_key) <> " not defined")
  end
end
