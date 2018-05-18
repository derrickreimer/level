defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  alias Ecto.Multi
  alias Level.Groups.Group
  alias Level.Posts.Post
  alias Level.Repo
  alias Level.Spaces.SpaceUser

  @doc """
  Posts a message to a group.
  """
  @spec post_to_group(SpaceUser.t(), Group.t(), map()) ::
          {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def post_to_group(space_user, group, params) do
    Multi.new()
    |> Multi.insert(:post, create_post_changeset(space_user, params))
    |> Repo.transaction()
  end

  defp create_post_changeset(space_user, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_user.space_id)
      |> Map.put(:space_user_id, space_user.id)

    %Post{}
    |> Post.create_changeset(params_with_relations)
  end
end
