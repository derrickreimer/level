defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  import Level.Gettext

  alias Ecto.Multi
  alias Level.Groups.Group
  alias Level.Posts.Post
  alias Level.Posts.PostGroup
  alias Level.Posts.Reply
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Spaces.SpaceUser

  @behaviour Level.DataloaderSource

  @typedoc "The result of posting to a group"
  @type post_to_group_result ::
          {:ok, %{post: Post.t(), post_group: PostGroup.t()}}
          | {:error, :post | :post_group, any(), %{optional(:post | :post_group) => any()}}

  @typedoc "The result of replying to a post"
  @type reply_to_post_result :: {:ok, %{reply: Reply.t()}} | {:error, Ecto.Changeset.t()}

  @doc """
  Fetches a post by id.
  """
  @spec get_post(SpaceUser.t(), String.t()) :: {:ok, Post.t()}
  def get_post(%SpaceUser{space_id: space_id}, id) do
    # TODO: scope this query
    case Repo.get_by(Post, space_id: space_id, id: id) do
      %Post{} = post ->
        {:ok, post}

      _ ->
        {:error, dgettext("errors", "Post not found")}
    end
  end

  @doc """
  Posts a message to a group.
  """
  @spec post_to_group(SpaceUser.t(), Group.t(), map()) :: post_to_group_result()
  def post_to_group(space_user, group, params) do
    operation =
      Multi.new()
      |> Multi.insert(:post, create_post_changeset(space_user, params))
      |> Multi.run(:post_group, fn %{post: post} ->
        create_post_group(space_user.space_id, post.id, group.id)
      end)

    case Repo.transaction(operation) do
      {:ok, %{post: post}} = result ->
        Pubsub.publish(:post_created, group.id, post)
        result

      err ->
        err
    end
  end

  @doc """
  Adds a reply to a post.
  """
  @spec reply_to_post(SpaceUser.t(), Post.t(), map()) :: reply_to_post_result()
  def reply_to_post(%SpaceUser{id: space_user_id, space_id: space_id}, %Post{id: post_id}, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_id)
      |> Map.put(:space_user_id, space_user_id)
      |> Map.put(:post_id, post_id)

    %Reply{}
    |> Reply.create_changeset(params_with_relations)
    |> Repo.insert()
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

  @impl true
  def dataloader_data(%{current_user: _user} = params) do
    Dataloader.Ecto.new(Repo, query: &dataloader_query/2, default_params: params)
  end

  def dataloader_data(_), do: raise("authentication required")

  @impl true
  # TODO: scope the query for posts
  def dataloader_query(Post, %{current_user: user}), do: Post
  def dataloader_query(_, _), do: raise("query not valid for this context")
end
