defmodule Level.Posts.CreatePost do
  @moduledoc false

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Level.Events
  alias Level.Groups.Group
  alias Level.Mentions
  alias Level.Posts
  alias Level.Posts.Post
  alias Level.Posts.PostGroup
  alias Level.Posts.PostLog
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
    |> log(group, author)
    |> Repo.transaction()
    |> after_transaction(author, group)
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

  defp log(multi, group, author) do
    Multi.run(multi, :log, fn %{post: post} ->
      PostLog.post_created(post, group, author)
    end)
  end

  defp after_transaction({:ok, %{post: post} = result}, author, group) do
    _ = subscribe_author(post, author)
    _ = subscribe_mentioned(post, result)
    _ = send_events(post, group, result)

    {:ok, result}
  end

  defp after_transaction(err, _, _), do: err

  defp subscribe_author(post, author) do
    _ = Posts.subscribe(author, [post])
  end

  defp subscribe_mentioned(post, %{mentions: mentioned_users}) do
    Enum.each(mentioned_users, fn mentioned_user ->
      _ = Posts.subscribe(mentioned_user, [post])
      _ = Posts.mark_as_unread(mentioned_user, [post])
    end)
  end

  defp send_events(post, group, %{mentions: mentioned_users}) do
    _ = Events.post_created(group.id, post)

    Enum.each(mentioned_users, fn %SpaceUser{id: id} ->
      _ = Events.user_mentioned(id, post)
    end)
  end
end
