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
  alias Level.Posts.Reply
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

  @behaviour Level.DataloaderSource

  @typedoc "The result of posting to a group"
  @type create_post_result ::
          {:ok, %{post: Post.t(), post_group: PostGroup.t()}}
          | {:error, :post | :post_group, any(), %{optional(:post | :post_group) => any()}}

  @typedoc "The result of replying to a post"
  @type reply_to_post_result :: {:ok, %{reply: Reply.t()}} | {:error, Ecto.Changeset.t()}

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
  Adds a reply to a post.
  """
  @spec reply_to_post(SpaceUser.t(), Post.t(), map()) :: reply_to_post_result()
  def reply_to_post(
        %SpaceUser{id: space_user_id, space_id: space_id},
        %Post{id: post_id} = post,
        params
      ) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_id)
      |> Map.put(:space_user_id, space_user_id)
      |> Map.put(:post_id, post_id)

    %Reply{}
    |> Reply.create_changeset(params_with_relations)
    |> Repo.insert()
    |> after_reply_to_post(post)
  end

  defp after_reply_to_post({:ok, %Reply{} = reply} = result, %Post{id: post_id}) do
    Pubsub.publish(:reply_created, post_id, reply)
    result
  end

  defp after_reply_to_post(err, _post), do: err

  @impl true
  def dataloader_data(%{current_user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &dataloader_query/2, default_params: params)
  end

  def dataloader_data(_), do: raise("authentication required")

  @impl true
  def dataloader_query(Post, %{current_user: user}), do: posts_base_query(user)
  def dataloader_query(_, _), do: raise("query not valid for this context")
end
