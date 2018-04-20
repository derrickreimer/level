defmodule Level.Posts do
  @moduledoc """
  The Posts context.
  """

  alias Level.Posts.Post
  alias Level.Repo
  alias Level.Spaces.Member

  @doc """
  Creates a new post.
  """
  @spec create_post(Member.t(), map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def create_post(member, params) do
    params_with_relations =
      params
      |> Map.put(:space_id, member.space_id)
      |> Map.put(:space_member_id, member.id)

    %Post{}
    |> Post.create_changeset(params_with_relations)
    |> Repo.insert()
  end
end
