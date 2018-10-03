defmodule Level.Posts.UpdatePost do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Level.Posts
  alias Level.Posts.Post
  alias Level.PostVersion
  alias Level.Repo
  alias Level.Spaces.SpaceUser

  @spec perform(SpaceUser.t(), Post.t(), map()) ::
          {:ok, %{original_post: Post.t(), updated_post: Post.t(), version: PostVersion.t()}}
          | {:error, :unauthorized}
          | {:error, atom(), any(), map()}
  def perform(%SpaceUser{} = space_user, %Post{} = post, params) do
    space_user
    |> Posts.can_edit?(post)
    |> after_authorization(post, params)
  end

  defp after_authorization(true, %Post{id: post_id}, params) do
    Multi.new()
    |> fetch_post_with_lock(post_id)
    |> store_version()
    |> update_post(params)
    |> Repo.transaction()
  end

  defp after_authorization(false, _, _) do
    {:error, :unauthorized}
  end

  # Obtain a row-level lock on the post in question, so
  # that we can safely insert a version record and update
  # the value in place without race conditions
  defp fetch_post_with_lock(multi, post_id) do
    Multi.run(multi, :original_post, fn _ ->
      query = from p in Post, where: p.id == ^post_id, lock: "FOR UPDATE"

      query
      |> Repo.one()
      |> handle_fetch_with_lock()
    end)
  end

  defp handle_fetch_with_lock(%Post{} = post), do: {:ok, post}
  defp handle_fetch_with_lock(_), do: {:error, :post_load_error}

  defp update_post(multi, params) do
    Multi.run(multi, :updated_post, fn %{original_post: original_post} ->
      original_post
      |> Post.update_changeset(params)
      |> Repo.update()
    end)
  end

  defp store_version(multi) do
    Multi.run(multi, :previous_version, fn %{original_post: original_post} ->
      params = %{
        space_id: original_post.space_id,
        author_id: original_post.space_user_id,
        post_id: original_post.id,
        body: original_post.body
      }

      %PostVersion{}
      |> PostVersion.create_changeset(params)
      |> Repo.insert()
    end)
  end
end
