defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  alias Level.Posts.Post
  alias Level.Repo
  alias Level.Spaces.User

  @typedoc "Valid params for creating a post"
  @type create_post_params :: %{required(:body) => String.t()}

  @doc """
  Creates a new post.
  """
  @spec create_post(User.t(), create_post_params()) ::
          {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def create_post(user, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, user.space_id)
      |> Map.put(:user_id, user.id)

    %Post{}
    |> Post.create_changeset(params_with_relations)
    |> Repo.insert()
  end
end
