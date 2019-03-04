defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext
  import Level.SearchConditions

  alias Ecto.Multi
  alias Level.Events
  alias Level.Markdown
  alias Level.Notifications
  alias Level.Posts
  alias Level.Posts.CreatePost
  alias Level.Posts.CreateReply
  alias Level.Posts.UpdatePost
  alias Level.Posts.UpdateReply
  alias Level.Repo
  alias Level.Schemas.File
  alias Level.Schemas.Group
  alias Level.Schemas.GroupUser
  alias Level.Schemas.Post
  alias Level.Schemas.PostFile
  alias Level.Schemas.PostGroup
  alias Level.Schemas.PostLog
  alias Level.Schemas.PostReaction
  alias Level.Schemas.PostUser
  alias Level.Schemas.PostUserLog
  alias Level.Schemas.PostVersion
  alias Level.Schemas.PostView
  alias Level.Schemas.Reply
  alias Level.Schemas.ReplyFile
  alias Level.Schemas.ReplyReaction
  alias Level.Schemas.ReplyView
  alias Level.Schemas.SearchResult
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  # TODO: make these types more specific

  @typedoc "The result of posting to a group"
  @type create_post_result :: {:ok, map()} | {:error, any(), any(), map()}

  @typedoc "The result of replying to a post"
  @type create_reply_result :: {:ok, map()} | {:error, any(), any(), map()}

  @typedoc "An author (either a space user or space bot)"
  @type author :: SpaceUser.t() | SpaceBot.t()

  @typedoc "The recipient of a post (either a group or a space user)"
  @type recipient :: Group.t() | SpaceUser.t()

  @doc """
  Builds a query for posts accessible to a particular user.
  """
  @spec posts_base_query(User.t() | SpaceUser.t()) :: Ecto.Query.t()
  def posts_base_query(user) do
    Posts.Query.base_query(user)
  end

  @doc """
  Builds a base query for searching posts.
  """
  @spec search_query(SpaceUser.t(), String.t(), integer()) :: Ecto.Query.t()
  def search_query(%SpaceUser{id: space_user_id, space_id: space_id}, term, limit) do
    preview_config = """
    StartSel=<mark>, StopSel=</mark>,
    MaxWords=35, MinWords=15, ShortWord=3, HighlightAll=FALSE,
    MaxFragments=0, FragmentDelimiter=" ... "
    """

    base_query =
      from ps in "post_searches",
        join: p in Post,
        on: p.id == ps.post_id,
        left_join: g in assoc(p, :groups),
        left_join: gu in GroupUser,
        on: gu.space_user_id == ^space_user_id and gu.group_id == g.id,
        left_join: pu in assoc(p, :post_users),
        on: pu.space_user_id == ^space_user_id,
        where: ps.space_id == type(^space_id, :binary_id),
        where: not is_nil(pu.id) or g.is_private == false or gu.access == "PRIVATE",
        where: ts_match(ps.search_vector, plainto_tsquery(ps.language, ^term)),
        where: p.state != "DELETED",
        order_by: [desc: p.inserted_at],
        limit: ^limit,
        select: %{
          id: fragment("? || ?", ps.searchable_type, ps.searchable_id),
          searchable_id: ps.searchable_id,
          searchable_type: ps.searchable_type,
          space_id: ps.space_id,
          post_id: ps.post_id,
          document: ps.document,
          language: fragment("?::text", ps.language),
          rank: ts_rank(ps.search_vector, plainto_tsquery(ps.language, ^term))
        }

    from ps in subquery(base_query),
      select: %SearchResult{
        id: ps.id,
        searchable_id: fragment("?::text", ps.searchable_id),
        searchable_type: fragment("?::text", ps.searchable_type),
        space_id: fragment("?::text", ps.space_id),
        post_id: fragment("?::text", ps.post_id),
        document: ps.document,
        language: ps.language,
        preview:
          ts_headline(
            fragment("?::regconfig", ps.language),
            ps.document,
            plainto_tsquery(fragment("?::regconfig", ps.language), ^term),
            ^preview_config
          )
      }
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
      left_join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == su.id and gu.group_id == g.id,
      left_join: pu in PostUser,
      on: pu.post_id == p.id and pu.space_user_id == su.id,
      where: r.is_deleted == false,
      where: not is_nil(pu.id) or g.is_private == false or gu.access == "PRIVATE",
      distinct: r.id
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

  @spec get_reply(User.t(), String.t()) :: {:ok, Reply.t()} | {:error, String.t()}
  def get_reply(%User{} = user, id) do
    user
    |> replies_base_query()
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
  Fetches replies by id.
  """
  @spec get_replies(User.t(), [String.t()]) :: {:ok, [Reply.t()]} | no_return()
  def get_replies(%User{} = user, ids) do
    user
    |> replies_base_query()
    |> where([r], r.id in ^ids)
    |> Repo.all()
    |> handle_get_replies()
  end

  defp handle_get_replies(replies) do
    {:ok, replies}
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
  @spec create_post(author(), recipient(), map()) :: create_post_result()
  def create_post(author, recipient, params) do
    CreatePost.perform(author, recipient, params)
  end

  @doc """
  Posts a message with recipients inferred from the body.
  """
  @spec create_post(author(), map()) :: create_post_result()
  def create_post(author, params) do
    CreatePost.perform(author, params)
  end

  @doc """
  Deletes a post.
  """
  @spec delete_post(SpaceUser.t(), Post.t()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def delete_post(_actor, post) do
    post
    |> Ecto.Changeset.change(state: "DELETED")
    |> Repo.update()
    |> after_delete_post()
  end

  defp after_delete_post({:ok, post} = result) do
    {:ok, space_user_ids} = Posts.get_accessor_ids(post)
    _ = Events.post_deleted(space_user_ids, post)
    result
  end

  defp after_delete_post(err), do: err

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
  Deletes a reply.
  """
  @spec delete_reply(SpaceUser.t(), Reply.t()) :: {:ok, Reply.t()} | {:error, Ecto.Changeset.t()}
  def delete_reply(_actor, reply) do
    reply
    |> Ecto.Changeset.change(is_deleted: true)
    |> Repo.update()
    |> after_delete_reply()
  end

  defp after_delete_reply({:ok, reply} = result) do
    {:ok, space_user_ids} = Posts.get_accessor_ids(reply)
    _ = Events.reply_deleted(space_user_ids, reply)
    result
  end

  defp after_delete_reply(err), do: err

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
    |> update_many_user_states(posts, %{subscription_state: "SUBSCRIBED", inbox_state: "UNREAD"})
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
    |> update_many_user_states(posts, %{subscription_state: "SUBSCRIBED", inbox_state: "READ"})
    |> after_mark_as_read(space_user)
  end

  defp after_mark_as_read({:ok, posts} = result, space_user) do
    Enum.each(posts, fn post ->
      PostUserLog.marked_as_read(post, space_user)
    end)

    Events.posts_marked_as_read(space_user.id, posts)
    Notifications.dismiss(space_user, posts)
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
  Records reply views.
  """
  @spec record_reply_views(SpaceUser.t(), [Reply.t()]) :: {:ok, [Reply.t()]}
  def record_reply_views(%SpaceUser{} = space_user, replies) do
    now = NaiveDateTime.utc_now()

    entries =
      replies
      |> Enum.map(fn reply ->
        [
          space_user_id: space_user.id,
          reply_id: reply.id,
          post_id: reply.post_id,
          space_id: reply.space_id,
          occurred_at: now
        ]
      end)

    ReplyView
    |> Repo.insert_all(entries)
    |> after_record_reply_views(space_user.id, replies)
  end

  defp after_record_reply_views(_result, space_user_id, replies) do
    Events.replies_viewed(space_user_id, replies)
    {:ok, replies}
  end

  @doc """
  Determines whether a user has viewed a reply.
  """
  @spec viewed_reply?(Reply.t(), SpaceUser.t()) :: boolean() | no_return()
  def viewed_reply?(%Reply{id: reply_id}, %SpaceUser{id: space_user_id}) do
    query =
      from rv in ReplyView,
        where: rv.reply_id == ^reply_id,
        where: rv.space_user_id == ^space_user_id,
        limit: 1

    Repo.all(query) != []
  end

  @doc """
  Render a post or reply body.
  """
  @spec render_body(String.t(), %{space: Space.t(), user: User.t()}) :: {:ok, String.t()}
  def render_body(raw_body, context \\ %{}) do
    {_status, html, _errors} = Markdown.to_html(raw_body, context)
    {:ok, html}
  end

  @doc """
  Determines if a user is allowed to edit a post.
  """
  @spec can_edit?(User.t(), SpaceUser.t()) :: boolean()
  def can_edit?(%User{} = current_user, %SpaceUser{} = post_author) do
    current_user.id == post_author.user_id
  end

  @spec can_edit?(SpaceUser.t(), Post.t()) :: boolean()
  def can_edit?(%SpaceUser{} = current_space_user, %Post{} = post) do
    current_space_user.id == post.space_user_id
  end

  @spec can_edit?(SpaceUser.t(), Reply.t()) :: boolean()
  def can_edit?(%SpaceUser{} = current_space_user, %Reply{} = reply) do
    current_space_user.id == reply.space_user_id
  end

  @doc """
  Updates a post.
  """
  @spec update_post(SpaceUser.t(), Post.t(), map()) ::
          {:ok, %{original_post: Post.t(), updated_post: Post.t(), version: PostVersion.t()}}
          | {:error, :unauthorized}
          | {:error, atom(), any(), map()}
  def update_post(%SpaceUser{} = space_user, %Post{} = post, params) do
    UpdatePost.perform(space_user, post, params)
  end

  @doc """
  Updates a reply.
  """
  @spec update_reply(SpaceUser.t(), Reply.t(), map()) ::
          {:ok, %{original_reply: Reply.t(), updated_reply: Reply.t(), version: ReplyVersion.t()}}
          | {:error, :unauthorized}
          | {:error, atom(), any(), map()}
  def update_reply(%SpaceUser{} = space_user, %Reply{} = reply, params) do
    UpdateReply.perform(space_user, reply, params)
  end

  @doc """
  Attaches files to a post.
  """
  @spec attach_files(Post.t(), [File.t()]) :: {:ok, [File.t()]} | no_return()
  def attach_files(%Post{} = post, files) do
    results =
      Enum.map(files, fn file ->
        params = %{
          space_id: post.space_id,
          post_id: post.id,
          file_id: file.id
        }

        %PostFile{}
        |> PostFile.create_changeset(params)
        |> Repo.insert()
        |> handle_file_attached(file)
      end)

    {:ok, Enum.reject(results, &is_nil/1)}
  end

  @spec attach_files(Reply.t(), [File.t()]) :: {:ok, [File.t()]} | no_return()
  def attach_files(%Reply{} = reply, files) do
    results =
      Enum.map(files, fn file ->
        params = %{
          space_id: reply.space_id,
          reply_id: reply.id,
          file_id: file.id
        }

        %ReplyFile{}
        |> ReplyFile.create_changeset(params)
        |> Repo.insert()
        |> handle_file_attached(file)
      end)

    {:ok, Enum.reject(results, &is_nil/1)}
  end

  def handle_file_attached({:ok, _}, file), do: file
  def handle_file_attached(_, _), do: nil

  @doc """
  Closes a post.
  """
  @spec close_post(SpaceUser.t(), Post.t()) ::
          {:ok, %{post: Post.t(), log: PostLog.t()}} | {:error, atom(), any(), any()}
  def close_post(%SpaceUser{} = closer, %Post{} = post) do
    Multi.new()
    |> Multi.update(:post, Ecto.Changeset.change(post, %{state: "CLOSED"}))
    |> log_post_closed(closer)
    |> Repo.transaction()
    |> after_post_closed(closer)
  end

  defp log_post_closed(multi, closer) do
    Multi.run(multi, :log, fn %{post: post} ->
      PostLog.post_closed(post, closer)
    end)
  end

  defp after_post_closed({:ok, %{post: post}} = result, closer) do
    {:ok, space_user_ids} = get_accessor_ids(post)

    _ = dismiss(closer, [post])
    _ = record_closed_notifications(post, closer)
    _ = Events.post_closed(space_user_ids, post)

    result
  end

  defp record_closed_notifications(post, closer) do
    {:ok, subscribers} = get_subscribers(post)

    Enum.each(subscribers, fn subscriber ->
      if subscriber.id !== closer.id do
        _ = Notifications.record_post_closed(subscriber, post)
      end
    end)
  end

  @doc """
  Reopens a post.
  """
  @spec reopen_post(SpaceUser.t(), Post.t()) :: {:ok, Post.t()}
  def reopen_post(%SpaceUser{} = space_user, %Post{} = post) do
    Multi.new()
    |> Multi.update(:post, Ecto.Changeset.change(post, %{state: "OPEN"}))
    |> log_post_reopened(space_user)
    |> Repo.transaction()
    |> after_post_reopened(space_user)
  end

  defp log_post_reopened(multi, space_user) do
    Multi.run(multi, :log, fn %{post: post} ->
      PostLog.post_reopened(post, space_user)
    end)
  end

  defp after_post_reopened({:ok, %{post: post}} = result, reopener) do
    {:ok, space_user_ids} = get_accessor_ids(post)

    _ = Events.post_reopened(space_user_ids, post)
    _ = record_reopened_notifications(post, reopener)

    result
  end

  defp record_reopened_notifications(post, reopener) do
    {:ok, subscribers} = get_subscribers(post)

    Enum.each(subscribers, fn subscriber ->
      if subscriber.id !== reopener.id do
        _ = Notifications.record_post_reopened(subscriber, post)
      end
    end)
  end

  @doc """
  Creates a reaction to a post.
  """
  @spec create_post_reaction(SpaceUser.t(), Post.t()) ::
          {:ok, PostReaction.t()} | {:error, Ecto.Changeset.t()}
  def create_post_reaction(%SpaceUser{} = space_user, %Post{} = post) do
    params = %{
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      post_id: post.id,
      value: "👍"
    }

    %PostReaction{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(on_conflict: :nothing, returning: true)
    |> after_create_post_reaction(space_user, post)
  end

  defp after_create_post_reaction({:ok, reaction}, space_user, post) do
    {:ok, space_user_ids} = get_accessor_ids(post)

    _ = PostLog.post_reaction_created(post, space_user)
    _ = Events.post_reaction_created(space_user_ids, post, reaction)

    {:ok, reaction}
  end

  defp after_create_post_reaction(err, _, _), do: err

  @doc """
  Deletes a reaction to a post.
  """
  @spec delete_post_reaction(SpaceUser.t(), Post.t()) ::
          {:ok, PostReaction.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def delete_post_reaction(%SpaceUser{id: space_user_id} = space_user, %Post{id: post_id} = post) do
    query =
      from pr in PostReaction,
        where: pr.space_user_id == ^space_user_id,
        where: pr.post_id == ^post_id,
        where: pr.value == "👍"

    case Repo.one(query) do
      %PostReaction{} = reaction ->
        reaction
        |> Repo.delete()
        |> after_delete_post_reaction(space_user, post)

      _ ->
        {:error, dgettext("errors", "Reaction not found")}
    end
  end

  defp after_delete_post_reaction({:ok, reaction}, _space_user, post) do
    {:ok, space_user_ids} = get_accessor_ids(post)
    _ = Events.post_reaction_deleted(space_user_ids, post, reaction)
    {:ok, reaction}
  end

  defp after_delete_post_reaction(err, _, _), do: err

  @doc """
  Creates a reaction to a reply.
  """
  @spec create_reply_reaction(SpaceUser.t(), Reply.t()) ::
          {:ok, PostReaction.t()} | {:error, Ecto.Changeset.t()}
  def create_reply_reaction(%SpaceUser{} = space_user, %Reply{} = reply) do
    params = %{
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      post_id: reply.post_id,
      reply_id: reply.id,
      value: "👍"
    }

    %ReplyReaction{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(on_conflict: :nothing, returning: true)
    |> after_create_reply_reaction(space_user, reply)
  end

  defp after_create_reply_reaction({:ok, reaction}, space_user, reply) do
    {:ok, space_user_ids} = get_accessor_ids(reply)

    _ = PostLog.reply_reaction_created(reply, space_user)
    _ = Events.reply_reaction_created(space_user_ids, reply, reaction)

    {:ok, reaction}
  end

  defp after_create_reply_reaction(err, _, _), do: err

  @doc """
  Deletes a reaction to a reply.
  """
  @spec delete_reply_reaction(SpaceUser.t(), Reply.t()) ::
          {:ok, PostReaction.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def delete_reply_reaction(
        %SpaceUser{id: space_user_id} = space_user,
        %Reply{id: reply_id} = reply
      ) do
    query =
      from pr in ReplyReaction,
        where: pr.space_user_id == ^space_user_id,
        where: pr.reply_id == ^reply_id,
        where: pr.value == "👍"

    case Repo.one(query) do
      %ReplyReaction{} = reaction ->
        reaction
        |> Repo.delete()
        |> after_delete_reply_reaction(space_user, reply)

      _ ->
        {:error, dgettext("errors", "Reaction not found")}
    end
  end

  defp after_delete_reply_reaction({:ok, reaction}, _space_user, reply) do
    {:ok, space_user_ids} = get_accessor_ids(reply)
    _ = Events.reply_reaction_deleted(space_user_ids, reply, reaction)
    {:ok, reaction}
  end

  defp after_delete_reply_reaction(err, _, _), do: err

  @doc """
  Determines if a user has reacted to a post.
  """
  @spec reacted?(SpaceUser.t(), Post.t()) :: boolean()
  def reacted?(%SpaceUser{id: space_user_id}, %Post{id: post_id}) do
    params = [space_user_id: space_user_id, post_id: post_id]

    case Repo.get_by(PostReaction, params) do
      %PostReaction{} -> true
      _ -> false
    end
  end

  @spec reacted?(User.t(), Post.t()) :: boolean()
  def reacted?(%User{id: user_id}, %Post{id: post_id}) do
    query =
      from pr in PostReaction,
        join: su in assoc(pr, :space_user),
        on: su.user_id == ^user_id,
        where: pr.post_id == ^post_id

    case Repo.one(query) do
      %PostReaction{} -> true
      _ -> false
    end
  end

  @spec reacted?(SpaceUser.t(), Reply.t()) :: boolean()
  def reacted?(%SpaceUser{id: space_user_id}, %Reply{id: reply_id}) do
    params = [space_user_id: space_user_id, reply_id: reply_id]

    case Repo.get_by(ReplyReaction, params) do
      %ReplyReaction{} -> true
      _ -> false
    end
  end

  @spec reacted?(User.t(), Reply.t()) :: boolean()
  def reacted?(%User{id: user_id}, %Reply{id: reply_id}) do
    query =
      from rr in ReplyReaction,
        join: su in assoc(rr, :space_user),
        on: su.user_id == ^user_id,
        where: rr.reply_id == ^reply_id

    case Repo.one(query) do
      %ReplyReaction{} -> true
      _ -> false
    end
  end

  @doc """
  Publishes a post to particular group.
  """
  @spec publish_to_group(Post.t(), Group.t()) ::
          {:ok, PostGroup.t()} | {:error, Ecto.Changeset.t()}
  def publish_to_group(%Post{} = post, %Group{} = group) do
    params = %{
      space_id: post.space_id,
      post_id: post.id,
      group_id: group.id
    }

    %PostGroup{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Determines if a post is privately-scoped.
  """
  @spec private?(Post.t()) :: {:ok, boolean()}
  def private?(%Post{} = post) do
    public_groups =
      post
      |> Ecto.assoc(:groups)
      |> where([g], g.is_private == false)
      |> limit(1)
      |> Repo.all()

    {:ok, Enum.empty?(public_groups)}
  end

  @doc """
  Fetches all the users who are allowed to see a post or reply.
  """
  @spec get_accessor_ids(Post.t()) :: {:ok, [String.t()]} | no_return()
  def get_accessor_ids(%Post{id: post_id, space_id: space_id} = post) do
    query =
      case private?(post) do
        {:ok, true} ->
          from su in SpaceUser,
            left_join: pg in PostGroup,
            on: pg.post_id == ^post_id,
            left_join: gu in GroupUser,
            on: gu.group_id == pg.group_id and gu.space_user_id == su.id,
            left_join: pu in PostUser,
            on: pu.space_user_id == su.id and pu.post_id == ^post_id,
            where: su.space_id == ^space_id,
            where: su.state == "ACTIVE",
            where: not is_nil(pu.id) or gu.access == "PRIVATE",
            distinct: su.id,
            select: su.id

        _ ->
          from su in SpaceUser,
            where: su.space_id == ^space_id,
            where: su.state == "ACTIVE",
            select: su.id
      end

    query
    |> Repo.all()
    |> after_get_accessors()
  end

  @spec get_accessor_ids(Reply.t()) :: {:ok, [String.t()]} | no_return()
  def get_accessor_ids(%Reply{post_id: post_id, space_id: space_id} = reply) do
    reply = Repo.preload(reply, :post)

    query =
      case private?(reply.post) do
        {:ok, true} ->
          from su in SpaceUser,
            left_join: pg in PostGroup,
            on: pg.post_id == ^post_id,
            left_join: gu in GroupUser,
            on: gu.group_id == pg.group_id and gu.space_user_id == su.id,
            left_join: pu in PostUser,
            on: pu.space_user_id == su.id and pu.post_id == ^post_id,
            where: su.space_id == ^space_id,
            where: su.state == "ACTIVE",
            where: not is_nil(pu.id) or gu.access == "PRIVATE",
            distinct: su.id,
            select: su.id

        _ ->
          from su in SpaceUser,
            where: su.space_id == ^space_id,
            where: su.state == "ACTIVE",
            select: su.id
      end

    query
    |> Repo.all()
    |> after_get_accessors()
  end

  defp after_get_accessors(ids) do
    {:ok, ids}
  end

  @doc """
  Calculate the last activity timestamp.
  """
  @spec last_activity_at(Post.t()) :: {:ok, DateTime.t()} | no_return()
  def last_activity_at(%Post{id: post_id} = post) do
    query =
      from pl in PostLog,
        where: pl.post_id == ^post_id,
        order_by: [desc: pl.occurred_at],
        limit: 1

    case Repo.one(query) do
      %PostLog{occurred_at: occurred_at} ->
        {:ok, occurred_at}

      _ ->
        {:ok, post.inserted_at}
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
