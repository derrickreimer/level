defmodule Level.Posts.CreatePost do
  @moduledoc false

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Level.Groups.Group
  alias Level.Mentions
  alias Level.Posts
  alias Level.Posts.Post
  alias Level.Posts.PostGroup
  alias Level.Posts.PostLog
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Spaces.SpaceUser

  # TODO: make this more specific
  @type result :: {:ok, map()} | {:error, any(), any(), map()}

  @doc """
  Adds a post to group.
  """
  @spec perform(SpaceUser.t(), Group.t(), map()) :: result()
  def perform(author, group, params) do
    Multi.new()
    |> do_insert(build_params(author, params))
    |> associate_with_group(group)
    |> record_mentions()
    |> log_create(group, author)
    |> Repo.transaction()
    |> subscribe_author(author)
    |> subscribe_mentioned()
    |> send_events(group)
  end

  defp build_params(author, params) do
    params
    |> Map.put(:space_id, author.space_id)
    |> Map.put(:space_user_id, author.id)
  end

  defp build_post_group_params(post, group) do
    %{
      space_id: post.space_id,
      post_id: post.id,
      group_id: group.id
    }
  end

  defp do_insert(multi, params) do
    Multi.insert(multi, :post, Post.create_changeset(%Post{}, params))
  end

  defp associate_with_group(multi, group) do
    Multi.run(multi, :post_group, fn %{post: post} ->
      %PostGroup{}
      |> Changeset.change(build_post_group_params(post, group))
      |> Repo.insert()
    end)
  end

  defp record_mentions(multi) do
    Multi.run(multi, :mentions, fn %{post: post} ->
      Mentions.record(post)
    end)
  end

  defp log_create(multi, group, author) do
    Multi.run(multi, :log, fn %{post: post} ->
      PostLog.insert(:post_created, post, group, author)
    end)
  end

  defp subscribe_author({:ok, %{post: post}} = result, author) do
    _ = Posts.subscribe(post, author)
    result
  end

  defp subscribe_author(err, _), do: err

  defp subscribe_mentioned({:ok, %{post: post, mentions: mentioned_users}} = result) do
    Enum.each(mentioned_users, fn mentioned_user ->
      _ = Posts.subscribe(post, mentioned_user)
      _ = Posts.mark_as_unread(post, mentioned_user)
    end)

    result
  end

  defp subscribe_mentioned(err), do: err

  defp send_events(
         {:ok, %{post: post, mentions: mentioned_users}} = result,
         %Group{id: group_id}
       ) do
    Pubsub.publish(:post_created, group_id, post)

    Enum.each(mentioned_users, fn %SpaceUser{id: id} ->
      Pubsub.publish(:user_mentioned, id, post)
    end)

    result
  end

  defp send_events(err, _), do: err
end
