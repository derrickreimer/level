defmodule Level.Posts.CreatePost do
  @moduledoc false

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Level.Events
  alias Level.Files
  alias Level.Mentions
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.Group
  alias Level.Schemas.Post
  alias Level.Schemas.PostGroup
  alias Level.Schemas.PostLog
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  # TODO: make this more specific
  @type result :: {:ok, map()} | {:error, any(), any(), map()}

  @doc """
  Creates a new post.
  """
  @spec perform(Posts.author(), Posts.recipient(), map()) :: result()
  def perform(%SpaceUser{} = author, %Group{} = group, params) do
    Multi.new()
    |> insert_post(build_params(author, params))
    |> associate_with_group(group)
    |> record_mentions()
    |> attach_files(author, params)
    |> log(group, author)
    |> Repo.transaction()
    |> after_user_post(author, group)
  end

  def perform(%SpaceBot{} = author, %SpaceUser{} = recipient, params) do
    Multi.new()
    |> insert_post(build_params(author, params))
    |> Repo.transaction()
    |> after_bot_post(recipient)
  end

  # Internal

  defp build_params(%SpaceUser{} = author, params) do
    params
    |> Map.put(:space_id, author.space_id)
    |> Map.put(:space_user_id, author.id)
  end

  defp build_params(%SpaceBot{} = author, params) do
    params
    |> Map.put(:space_id, author.space_id)
    |> Map.put(:space_bot_id, author.id)
  end

  defp build_post_group_params(post, group) do
    %{
      space_id: post.space_id,
      post_id: post.id,
      group_id: group.id
    }
  end

  defp insert_post(multi, params) do
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

  defp attach_files(multi, author, %{file_ids: file_ids}) do
    Multi.run(multi, :files, fn %{post: post} ->
      files = Files.get_files(author, file_ids)
      Posts.attach_files(post, files)
    end)
  end

  defp attach_files(multi, _, _) do
    Multi.run(multi, :files, fn _ -> {:ok, []} end)
  end

  defp log(multi, group, author) do
    Multi.run(multi, :log, fn %{post: post} ->
      PostLog.post_created(post, group, author)
    end)
  end

  defp after_user_post({:ok, result}, author, group) do
    _ = Posts.subscribe(author, [result.post])
    _ = subscribe_mentioned(result.post, result)
    _ = send_events(result.post, group, result)

    {:ok, result}
  end

  defp after_user_post(err, _, _), do: err

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

  defp after_bot_post({:ok, result}, recipient) do
    _ = Posts.subscribe(recipient, [result.post])
    _ = Posts.mark_as_unread(recipient, [result.post])

    {:ok, result}
  end

  defp after_bot_post(err, _), do: err
end
