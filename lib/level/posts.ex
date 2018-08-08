defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  import Level.Gettext

  alias Ecto.Multi
  alias Level.Groups.Group
  alias Level.Groups.GroupUser
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

  @behaviour Level.DataloaderSource

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

  TODO: add a notion of being "subscribed" to a post?
  """
  @spec posts_base_query(User.t()) :: Ecto.Query.t()
  @spec posts_base_query(SpaceUser.t()) :: Ecto.Query.t()

  def posts_base_query(%User{id: user_id} = _user) do
    from p in Post,
      join: su in SpaceUser,
      on: su.space_id == p.space_id and su.user_id == ^user_id,
      join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == su.id and gu.group_id == g.id,
      left_join: pu in PostUser,
      on: pu.space_user_id == su.id and pu.post_id == p.id,
      where: g.is_private == false or not is_nil(gu.id),
      select: %{
        p
        | subscription_state: fragment("coalesce(?, ?)", pu.subscription_state, "NOT_SUBSCRIBED")
      }
  end

  def posts_base_query(%SpaceUser{id: space_user_id} = _space_user) do
    from p in Post,
      join: g in assoc(p, :groups),
      left_join: gu in GroupUser,
      on: gu.space_user_id == ^space_user_id and gu.group_id == g.id,
      where: g.is_private == false or not is_nil(gu.id),
      left_join: pu in PostUser,
      on: pu.space_user_id == ^space_user_id and pu.post_id == p.id,
      select: %{
        p
        | subscription_state: fragment("coalesce(?, ?)", pu.subscription_state, "NOT_SUBSCRIBED")
      }
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
  def create_post(space_user, group, params) do
    Multi.new()
    |> Multi.insert(:post, create_post_changeset(space_user, params))
    |> Multi.run(:post_group, fn %{post: post} ->
      create_post_group(space_user.space_id, post.id, group.id)
    end)
    |> Multi.run(:subscribe, fn %{post: post} ->
      {:ok, subscribe(post, space_user)}
    end)
    |> Multi.run(:log, fn %{post: post} ->
      PostLog.insert(:post_created, post, group, space_user)
    end)
    |> Repo.transaction()
    |> after_create_post(space_user, group)
  end

  defp create_post_changeset(space_user, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_user.space_id)
      |> Map.put(:space_user_id, space_user.id)

    %Post{}
    |> Post.create_changeset(params_with_relations)
  end

  defp create_post_group(space_id, post_id, group_id) do
    params = %{
      space_id: space_id,
      post_id: post_id,
      group_id: group_id
    }

    %PostGroup{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert()
  end

  defp after_create_post(
         {:ok, %{post: %Post{id: post_id}} = data},
         %SpaceUser{} = space_user,
         %Group{id: group_id}
       ) do
    {:ok, post} = get_post(space_user, post_id)
    Pubsub.publish(:post_created, group_id, post)
    {:ok, %{data | post: post}}
  end

  defp after_create_post(err, _space_user, _group), do: err

  @doc """
  Subscribes a user to a post.
  """
  @spec subscribe(Post.t(), SpaceUser.t()) :: :ok | :error | no_return()
  def subscribe(
        %Post{id: post_id, space_id: space_id},
        %SpaceUser{id: space_user_id} = space_user
      ) do
    params = %{
      space_id: space_id,
      post_id: post_id,
      space_user_id: space_user_id,
      subscription_state: "SUBSCRIBED"
    }

    %PostUser{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:post_id, :space_user_id]
    )
    |> after_subscribe(space_user, post_id)
  end

  defp after_subscribe({:ok, _}, space_user, post_id) do
    # Fetch a clean copy of the post with contextual data included
    case get_post(space_user, post_id) do
      {:ok, post} ->
        Pubsub.publish(:post_subscribed, space_user.id, post)
        :ok

      _ ->
        :error
    end
  end

  defp after_subscribe(_, _, _), do: :error

  @doc """
  Unsubscribes a user from a post.
  """
  @spec unsubscribe(Post.t(), SpaceUser.t()) :: :ok | no_return()
  def unsubscribe(
        %Post{id: post_id, space_id: space_id},
        %SpaceUser{id: space_user_id} = space_user
      ) do
    params = %{
      space_id: space_id,
      post_id: post_id,
      space_user_id: space_user_id,
      subscription_state: "UNSUBSCRIBED"
    }

    %PostUser{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:post_id, :space_user_id]
    )
    |> after_unsubscribe(space_user, post_id)
  end

  defp after_unsubscribe({:ok, _}, space_user, post_id) do
    # Fetch a clean copy of the post with contextual data included
    case get_post(space_user, post_id) do
      {:ok, post} ->
        Pubsub.publish(:post_unsubscribed, space_user.id, post)
        :ok

      _ ->
        :error
    end
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
  def create_reply(
        %SpaceUser{id: space_user_id, space_id: space_id} = space_user,
        %Post{id: post_id} = post,
        params
      ) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_id)
      |> Map.put(:space_user_id, space_user_id)
      |> Map.put(:post_id, post_id)

    Multi.new()
    |> Multi.insert(:reply, Reply.create_changeset(%Reply{}, params_with_relations))
    |> Multi.run(:subscribe, fn _ -> {:ok, subscribe(post, space_user)} end)
    |> Multi.run(:log, fn %{reply: reply} ->
      PostLog.insert(:reply_created, post, reply, space_user)
    end)
    |> Multi.run(:post_view, fn %{reply: reply} ->
      record_view(post, space_user, reply)
    end)
    |> Repo.transaction()
    |> after_create_reply(post)
  end

  defp after_create_reply({:ok, %{reply: %Reply{} = reply}} = result, %Post{id: post_id}) do
    Pubsub.publish(:reply_created, post_id, reply)
    result
  end

  defp after_create_reply(err, _post), do: err

  @doc """
  Records a view event.
  """
  @spec record_view(Post.t(), SpaceUser.t(), Reply.t()) ::
          {:ok, PostView.t()} | {:error, Ecto.Changeset.t()}
  @spec record_view(Post.t(), SpaceUser.t()) :: {:ok, PostView.t()} | {:error, Ecto.Changeset.t()}

  def record_view(%Post{} = post, %SpaceUser{} = space_user, %Reply{} = reply) do
    PostView.insert(post, space_user, reply)
  end

  def record_view(%Post{} = post, %SpaceUser{} = space_user) do
    PostView.insert(post, space_user)
  end

  @impl true
  def dataloader_data(%{current_user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &dataloader_query/2, default_params: params)
  end

  def dataloader_data(_), do: raise("authentication required")

  @impl true
  def dataloader_query(Post, %{current_user: user}), do: posts_base_query(user)
  def dataloader_query(_, _), do: raise("query not valid for this context")
end
