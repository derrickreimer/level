defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  alias Ecto.Multi
  alias Level.Groups.Group
  alias Level.Posts.Post
  alias Level.Posts.PostGroup
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Spaces.SpaceUser

  @typedoc "The result of posting to a group"
  @type post_to_group_result ::
          {:ok, %{post: Post.t(), post_group: PostGroup.t()}}
          | {:error, :post | :post_group, any(), %{optional(:post | :post_group) => any()}}

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
        Pubsub.publish(:post_created, space_user.id, post)
        result

      err ->
        err
    end
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
end
