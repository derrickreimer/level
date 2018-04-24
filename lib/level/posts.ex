defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  alias Level.Posts.Post
  alias Level.Repo
  alias Level.Spaces.SpaceUser

  @doc """
  Creates a new post.
  """
  @spec create_post(SpaceUser.t(), map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def create_post(space_user, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, space_user.space_id)
      |> Map.put(:space_user_id, space_user.id)

    %Post{}
    |> Post.create_changeset(params_with_relations)
    |> Repo.insert()
  end
end
