defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Groups.Group
  alias Level.Groups.GroupUser
  alias Level.Markdown
  alias Level.Mentions
  alias Level.Posts.Post
  alias Level.Posts.PostGroup
  alias Level.Posts.PostLog
  alias Level.Posts.PostUser
  alias Level.Posts.PostView
  alias Level.Posts.Reply
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  @typedoc "The result of posting to a group"
  @type create_post_result ::
          {:ok, %{post: Post.t(), post_group: PostGroup.t(), subscribe: :ok, log: PostLog.t()}}
          | {:error, :post | :post_group | :subscribe | :log, any(),
             %{optional(:post | :post_group | :subscribe | :log) => any()}}

  @typedoc "The result of replying to a post"
  @type create_reply_result ::
          {:ok, %{reply: Reply.t(), subscribe: :ok}}
          | {:error, :reply | :subscribe, any(), %{optional(:reply | :subscribe) => any()}}

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
  Posts a message to a group.
  """
  @spec create_post(SpaceUser.t(), Group.t(), map()) :: create_post_result()
  def create_post(author, group, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, author.space_id)
      |> Map.put(:space_user_id, author.id)

    Multi.new()
    |> insert_post(params_with_relations)
    |> associate_with_group(group)
    |> record_post_mentions()
    |> log_post_created(group, author)
    |> Repo.transaction()
    |> after_create_post(author, group)
  end

  defp insert_post(multi, params) do
    Multi.insert(multi, :post, Post.create_changeset(%Post{}, params))
  end

  defp associate_with_group(multi, group) do
    Multi.run(multi, :post_group, fn %{post: post} ->
      %PostGroup{}
      |> Ecto.Changeset.change(%{space_id: post.space_id, post_id: post.id, group_id: group.id})
      |> Repo.insert()
    end)
  end

  defp record_post_mentions(multi) do
    Multi.run(multi, :mentions, fn %{post: post} ->
      Mentions.record(post)
    end)
  end

  defp log_post_created(multi, group, author) do
    Multi.run(multi, :log, fn %{post: post} ->
      PostLog.insert(:post_created, post, group, author)
    end)
  end

  defp after_create_post(
         {:ok, %{post: post, mentions: mentioned_ids}} = result,
         author,
         %Group{id: group_id}
       ) do
    _ = subscribe(post, author)
    Pubsub.publish(:post_created, group_id, post)

    Enum.each(mentioned_ids, fn id ->
      Pubsub.publish(:user_mentioned, id, post)
    end)

    result
  end

  defp after_create_post(err, _author, _group), do: err

  @doc """
  Subscribes a user to a post.
  """
  @spec subscribe(Post.t(), SpaceUser.t()) :: :ok | :error | no_return()
  def subscribe(%Post{} = post, %SpaceUser{id: space_user_id}) do
    params = %{
      space_id: post.space_id,
      post_id: post.id,
      space_user_id: space_user_id,
      subscription_state: "SUBSCRIBED"
    }

    %PostUser{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:post_id, :space_user_id]
    )
    |> after_subscribe(space_user_id, post)
  end

  defp after_subscribe({:ok, _}, space_user_id, post) do
    Pubsub.publish(:post_subscribed, space_user_id, post)
    :ok
  end

  defp after_subscribe(_, _, _), do: :error

  @doc """
  Unsubscribes a user from a post.
  """
  @spec unsubscribe(Post.t(), SpaceUser.t()) :: :ok | :error | no_return()
  def unsubscribe(%Post{} = post, %SpaceUser{id: space_user_id}) do
    params = %{
      space_id: post.space_id,
      post_id: post.id,
      space_user_id: space_user_id,
      subscription_state: "UNSUBSCRIBED"
    }

    %PostUser{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:post_id, :space_user_id]
    )
    |> after_unsubscribe(space_user_id, post)
  end

  defp after_unsubscribe({:ok, _}, space_user_id, post) do
    Pubsub.publish(:post_unsubscribed, space_user_id, post)
    :ok
  end

  defp after_unsubscribe(_, _, _), do: :error

  @doc """
  Determines a user's subscription state with a post.
  """
  @spec get_subscription_state(Post.t(), SpaceUser.t()) ::
          :subscribed | :unsubscribed | :not_subscribed | no_return()
  def get_subscription_state(%Post{id: post_id}, %SpaceUser{id: space_user_id}) do
    case Repo.get_by(PostUser, %{post_id: post_id, space_user_id: space_user_id}) do
      %PostUser{subscription_state: state} ->
        parse_subscription_state(state)

      _ ->
        :not_subscribed
    end
  end

  defp parse_subscription_state("SUBSCRIBED"), do: :subscribed
  defp parse_subscription_state("UNSUBSCRIBED"), do: :unsubscribed

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
  Adds a reply to a post.
  """
  @spec create_reply(SpaceUser.t(), Post.t(), map()) :: create_reply_result()
  def create_reply(%SpaceUser{} = author, %Post{} = post, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, author.space_id)
      |> Map.put(:space_user_id, author.id)
      |> Map.put(:post_id, post.id)

    Multi.new()
    |> insert_reply(params_with_relations)
    |> record_reply_mentions(post)
    |> log_reply_created(post, author)
    |> record_view_upon_reply(post, author)
    |> Repo.transaction()
    |> after_create_reply(author, post)
  end

  defp insert_reply(multi, params) do
    Multi.insert(multi, :reply, Reply.create_changeset(%Reply{}, params))
  end

  defp record_reply_mentions(multi, post) do
    Multi.run(multi, :mentions, fn %{reply: reply} ->
      Mentions.record(post, reply)
    end)
  end

  defp log_reply_created(multi, post, space_user) do
    Multi.run(multi, :log, fn %{reply: reply} ->
      PostLog.insert(:reply_created, post, reply, space_user)
    end)
  end

  def record_view_upon_reply(multi, post, space_user) do
    Multi.run(multi, :post_view, fn %{reply: reply} ->
      record_view(post, space_user, reply)
    end)
  end

  defp after_create_reply(
         {:ok, %{reply: reply, mentions: mentioned_ids}} = result,
         author,
         %Post{id: post_id} = post
       ) do
    _ = subscribe(post, author)
    Pubsub.publish(:reply_created, post_id, reply)

    Enum.each(mentioned_ids, fn id ->
      Pubsub.publish(:user_mentioned, id, post)
    end)

    result
  end

  defp after_create_reply(err, _author, _post), do: err

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
        classes =
          if handle == current_user.handle do
            " is-viewer"
          else
            ""
          end

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
end
