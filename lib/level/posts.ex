defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext

  alias Level.Events
  alias Level.Groups.Group
  alias Level.Groups.GroupUser
  alias Level.Markdown
  alias Level.Mentions
  alias Level.Posts.CreatePost
  alias Level.Posts.CreateReply
  alias Level.Posts.Post
  alias Level.Posts.PostUser
  alias Level.Posts.PostUserLog
  alias Level.Posts.PostView
  alias Level.Posts.Reply
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  # TODO: make these types more specific

  @typedoc "The result of posting to a group"
  @type create_post_result :: {:ok, map()} | {:error, any(), any(), map()}

  @typedoc "The result of replying to a post"
  @type create_reply_result :: {:ok, map()} | {:error, any(), any(), map()}

  @doc """
  Builds a query for posts accessible to a particular user.
  """
  @spec posts_base_query(User.t()) :: Ecto.Query.t()
  def posts_base_query(%User{id: user_id} = _user) do
    from p in Post,
      join: su in SpaceUser,
      on: su.space_id == p.space_id and su.user_id == ^user_id,
      join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == su.id and gu.group_id == g.id,
      where: g.is_private == false or not is_nil(gu.id)
  end

  @spec posts_base_query(SpaceUser.t()) :: Ecto.Query.t()
  def posts_base_query(%SpaceUser{id: space_user_id} = _space_user) do
    from p in Post,
      join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == ^space_user_id and gu.group_id == g.id,
      where: g.is_private == false or not is_nil(gu.id)
  end

  @doc """
  Builds a query for posts accessible to a particular user.
  """
  @spec replies_base_query(User.t()) :: Ecto.Query.t()
  def replies_base_query(%User{id: user_id} = _user) do
    from r in Reply,
      join: su in SpaceUser,
      on: su.space_id == r.space_id and su.user_id == ^user_id,
      join: p in assoc(r, :post),
      join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == su.id and gu.group_id == g.id,
      where: g.is_private == false or not is_nil(gu.id)
  end

  @doc """
  Fetches a post by id.
  """
  @spec get_post(SpaceUser.t(), String.t()) :: {:ok, Post.t()} | {:error, String.t()}
  def get_post(%SpaceUser{} = space_user, id) do
    space_user
    |> posts_base_query()
    |> Repo.get_by(id: id)
    |> handle_post_query()
  end

  @spec get_post(User.t(), String.t()) :: {:ok, Post.t()} | {:error, String.t()}
  def get_post(%User{} = user, id) do
    user
    |> posts_base_query()
    |> Repo.get_by(id: id)
    |> handle_post_query()
  end

  defp handle_post_query(%Post{} = post) do
    {:ok, post}
  end

  defp handle_post_query(_) do
    {:error, dgettext("errors", "Post not found")}
  end

  @doc """
  Fetches multiple posts by id.
  """
  @spec get_posts(SpaceUser.t(), [String.t()]) :: {:ok, [Post.t()]} | no_return()
  def get_posts(%SpaceUser{} = space_user, ids) do
    space_user
    |> posts_base_query()
    |> where([p], p.id in ^ids)
    |> Repo.all()
    |> handle_posts_query()
  end

  @spec get_posts(User.t(), [String.t()]) :: {:ok, [Post.t()]} | no_return()
  def get_posts(%User{} = user, ids) do
    user
    |> posts_base_query()
    |> where([p], p.id in ^ids)
    |> Repo.all()
    |> handle_posts_query()
  end

  defp handle_posts_query(posts) do
    {:ok, posts}
  end

  @doc """
  Fetches a reply.
  """
  @spec get_reply(Post.t(), String.t()) :: {:ok, Reply.t()} | {:error, String.t()}
  def get_reply(%Post{} = post, id) do
    post
    |> Ecto.assoc(:replies)
    |> Repo.get_by(id: id)
    |> handle_reply_query()
  end

  defp handle_reply_query(%Reply{} = reply) do
    {:ok, reply}
  end

  defp handle_reply_query(_) do
    {:error, dgettext("errors", "Reply not found")}
  end

  @doc """
  Fetches post subscribers.
  """
  @spec get_subscribers(Post.t()) :: {:ok, [SpaceUser.t()]}
  def get_subscribers(%Post{id: post_id}) do
    query =
      from su in SpaceUser,
        join: pu in assoc(su, :post_users),
        on: pu.post_id == ^post_id and pu.subscription_state == "SUBSCRIBED"

    query
    |> Repo.all()
    |> handle_get_subscribers()
  end

  defp handle_get_subscribers(subscribers) do
    {:ok, subscribers}
  end

  @doc """
  Posts a message to a group.
  """
  @spec create_post(SpaceUser.t(), Group.t(), map()) :: create_post_result()
  def create_post(author, group, params) do
    CreatePost.perform(author, group, params)
  end

  @doc """
  Adds a reply to a post.
  """
  @spec create_reply(SpaceUser.t(), Post.t(), map()) :: create_reply_result()
  def create_reply(%SpaceUser{} = author, %Post{} = post, params) do
    CreateReply.perform(author, post, params,
      presence: LevelWeb.Presence,
      web_push: Level.WebPush,
      events: Level.Events
    )
  end

  @doc """
  Subscribes a user to the given posts.
  """
  @spec subscribe(SpaceUser.t(), [Post.t()]) :: {:ok, [Post.t()]}
  def subscribe(%SpaceUser{} = space_user, posts) do
    space_user
    |> update_many_user_states(posts, %{subscription_state: "SUBSCRIBED"})
    |> after_subscribe(space_user)
  end

  defp after_subscribe({:ok, posts} = result, space_user) do
    Enum.each(posts, fn post ->
      PostUserLog.subscribed(post, space_user)
    end)

    Events.posts_subscribed(space_user.id, posts)
    result
  end

  @doc """
  Unsubscribes a user from the given posts.
  """
  @spec unsubscribe(SpaceUser.t(), [Post.t()]) :: {:ok, [Post.t()]}
  def unsubscribe(%SpaceUser{} = space_user, posts) do
    space_user
    |> update_many_user_states(posts, %{subscription_state: "UNSUBSCRIBED"})
    |> after_unsubscribe(space_user)
  end

  defp after_unsubscribe({:ok, posts} = result, space_user) do
    Enum.each(posts, fn post ->
      PostUserLog.unsubscribed(post, space_user)
    end)

    Events.posts_unsubscribed(space_user.id, posts)
    result
  end

  @doc """
  Marks the given posts as unread.
  """
  @spec mark_as_unread(SpaceUser.t(), [Post.t()]) :: {:ok, [Post.t()]}
  def mark_as_unread(%SpaceUser{} = space_user, posts) do
    space_user
    |> update_many_user_states(posts, %{inbox_state: "UNREAD"})
    |> after_mark_as_unread(space_user)
  end

  defp after_mark_as_unread({:ok, posts} = result, space_user) do
    Enum.each(posts, fn post ->
      PostUserLog.marked_as_unread(post, space_user)
    end)

    Events.posts_marked_as_unread(space_user.id, posts)
    result
  end

  @doc """
  Marks the given posts as read.
  """
  @spec mark_as_read(SpaceUser.t(), [Post.t()]) :: {:ok, [Post.t()]}
  def mark_as_read(%SpaceUser{} = space_user, posts) do
    space_user
    |> update_many_user_states(posts, %{inbox_state: "READ"})
    |> after_mark_as_read(space_user)
  end

  defp after_mark_as_read({:ok, posts} = result, space_user) do
    Enum.each(posts, fn post ->
      PostUserLog.marked_as_read(post, space_user)
    end)

    Events.posts_marked_as_read(space_user.id, posts)
    result
  end

  @doc """
  Dismisses the given posts from the inbox.
  """
  @spec dismiss(SpaceUser.t(), [Post.t()]) :: {:ok, [Post.t()]}
  def dismiss(%SpaceUser{} = space_user, posts) do
    space_user
    |> update_many_user_states(posts, %{inbox_state: "DISMISSED"})
    |> after_dismiss(space_user)
  end

  defp after_dismiss({:ok, posts} = result, space_user) do
    Enum.each(posts, fn post ->
      PostUserLog.dismissed(post, space_user)
    end)

    Events.posts_dismissed(space_user.id, posts)
    result
  end

  @doc """
  Fetches state attributes describing a user's relationship to a post.
  """
  @spec get_user_state(Post.t(), SpaceUser.t()) :: %{inbox: String.t(), subscription: String.t()}
  def get_user_state(%Post{id: post_id}, %SpaceUser{id: space_user_id}) do
    case Repo.get_by(PostUser, %{post_id: post_id, space_user_id: space_user_id}) do
      %PostUser{inbox_state: inbox_state, subscription_state: subscription_state} ->
        %{inbox: inbox_state, subscription: subscription_state}

      _ ->
        %{inbox: "EXCLUDED", subscription: "NOT_SUBSCRIBED"}
    end
  end

  @doc """
  Records a view event.
  """
  @spec record_view(Post.t(), SpaceUser.t(), Reply.t()) ::
          {:ok, PostView.t()} | {:error, Ecto.Changeset.t()}
  def record_view(%Post{} = post, %SpaceUser{} = space_user, %Reply{} = reply) do
    do_record_view(%{
      space_id: post.space_id,
      post_id: post.id,
      space_user_id: space_user.id,
      last_viewed_reply_id: reply.id
    })
  end

  @spec record_view(Post.t(), SpaceUser.t()) :: {:ok, PostView.t()} | {:error, Ecto.Changeset.t()}
  def record_view(%Post{} = post, %SpaceUser{} = space_user) do
    do_record_view(%{
      space_id: post.space_id,
      post_id: post.id,
      space_user_id: space_user.id
    })
  end

  defp do_record_view(params) do
    %PostView{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end

  @doc """
  Render a post or reply body.
  """
  @spec render_body(String.t(), User.t()) :: {:ok, String.t()}
  def render_body(raw_body, current_user) do
    raw_body
    |> render_markdown()
    |> render_mentions(current_user)
  end

  defp render_markdown(raw_body) do
    {_status, html, _errors} = Markdown.to_html(raw_body)
    {:ok, html}
  end

  defp render_mentions({:ok, html}, current_user) do
    replaced_html =
      Regex.replace(Mentions.handle_pattern(), html, fn match, handle ->
        String.replace(
          match,
          "@#{handle}",
          "<strong class=\"#{mention_classes(handle, current_user)}\">@#{handle}</strong>"
        )
      end)

    {:ok, replaced_html}
  end

  defp mention_classes(handle, %User{handle: viewer_handle}) do
    if String.downcase(handle) == String.downcase(viewer_handle) do
      "user-mention is-viewer"
    else
      "user-mention"
    end
  end

  # Internal

  defp update_many_user_states(space_user, posts, params) do
    updated_posts =
      Enum.filter(posts, fn post ->
        :ok == update_user_state(space_user, post, params)
      end)

    {:ok, updated_posts}
  end

  defp update_user_state(space_user, post, params) do
    full_params =
      params
      |> Map.put(:space_id, post.space_id)
      |> Map.put(:post_id, post.id)
      |> Map.put(:space_user_id, space_user.id)

    %PostUser{}
    |> Ecto.Changeset.change(full_params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:post_id, :space_user_id]
    )
    |> after_update_user_state()
  end

  defp after_update_user_state({:ok, _}), do: :ok
  defp after_update_user_state(_), do: :error
end
