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
  alias Level.Posts.PostUser
  alias Level.Posts.Reply
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  @behaviour Level.DataloaderSource

  @typedoc "The result of posting to a group"
  @type create_post_result ::
          {:ok, %{post: Post.t(), post_group: PostGroup.t(), subscribe: :ok}}
          | {:error, :post | :post_group | :subscribe, any(),
             %{optional(:post | :post_group | :subscribe) => any()}}

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
      where: g.is_private == false or not is_nil(gu.id)
  end

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
    |> Repo.transaction()
    |> after_create_post(group)
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

  defp after_create_post({:ok, %{post: %Post{} = post}} = result, %Group{id: group_id}) do
    Pubsub.publish(:post_created, group_id, post)
    result
  end

  defp after_create_post(err, _group), do: err

  @doc """
  Subscribes a user to a post.
  """
  @spec subscribe(Post.t(), SpaceUser.t()) :: :ok | no_return()
  def subscribe(%Post{id: post_id, space_id: space_id}, %SpaceUser{id: space_user_id}) do
    params = %{
      space_id: space_id,
      post_id: post_id,
      space_user_id: space_user_id,
      state: "SUBSCRIBED"
    }

    %PostUser{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:post_id, :space_user_id]
    )

    :ok
  end

  @doc """
  Unsubscribes a user from a post.
  """
  @spec unsubscribe(Post.t(), SpaceUser.t()) :: :ok | no_return()
  def unsubscribe(%Post{id: post_id, space_id: space_id}, %SpaceUser{id: space_user_id}) do
    params = %{
      space_id: space_id,
      post_id: post_id,
      space_user_id: space_user_id,
      state: "UNSUBSCRIBED"
    }

    %PostUser{}
    |> Ecto.Changeset.change(params)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:post_id, :space_user_id]
    )

    :ok
  end

  @doc """
  Determines a user's subscription state with a post.
  """
  @spec get_subscription_state(Post.t(), SpaceUser.t()) ::
          :subscribed | :unsubscribed | :not_subscribed | no_return()
  def get_subscription_state(%Post{id: post_id}, %SpaceUser{id: space_user_id}) do
    case Repo.get_by(PostUser, %{post_id: post_id, space_user_id: space_user_id}) do
      %PostUser{state: state} ->
        parse_subscription_state(state)

      _ ->
        :not_subscribed
    end
  end

  defp parse_subscription_state("SUBSCRIBED"), do: :subscribed
  defp parse_subscription_state("UNSUBSCRIBED"), do: :unsubscribed

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
    |> Repo.transaction()
    |> after_create_reply(post)
  end

  defp after_create_reply({:ok, %{reply: %Reply{} = reply}} = result, %Post{id: post_id}) do
    Pubsub.publish(:reply_created, post_id, reply)
    result
  end

  defp after_create_reply(err, _post), do: err

  @impl true
  def dataloader_data(%{current_user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &dataloader_query/2, default_params: params)
  end

  def dataloader_data(_), do: raise("authentication required")

  @impl true
  def dataloader_query(Post, %{current_user: user}), do: posts_base_query(user)
  def dataloader_query(_, _), do: raise("query not valid for this context")
end
