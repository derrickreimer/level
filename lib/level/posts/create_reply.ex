defmodule Level.Posts.CreateReply do
  @moduledoc false

  alias Ecto.Multi
  alias Level.Mentions
  alias Level.Posts
  alias Level.Posts.Post
  alias Level.Posts.PostLog
  alias Level.Posts.Reply
  alias Level.Pubsub
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Users
  alias Level.WebPush
  alias Level.WebPush.Payload

  # TODO: make this more specific
  @type result :: {:ok, map()} | {:error, any(), any(), map()}

  @doc """
  Adds a reply to post.
  """
  @spec perform(SpaceUser.t(), Post.t(), map()) :: result()
  def perform(%SpaceUser{} = author, %Post{} = post, params) do
    Multi.new()
    |> do_insert(build_params(author, post, params))
    |> record_mentions(post)
    |> log_create(post, author)
    |> record_view(post, author)
    |> Repo.transaction()
    |> after_transaction(post, author)
  end

  defp build_params(author, post, params) do
    params
    |> Map.put(:space_id, author.space_id)
    |> Map.put(:space_user_id, author.id)
    |> Map.put(:post_id, post.id)
  end

  defp do_insert(multi, params) do
    Multi.insert(multi, :reply, Reply.create_changeset(%Reply{}, params))
  end

  defp record_mentions(multi, post) do
    Multi.run(multi, :mentions, fn %{reply: reply} ->
      Mentions.record(post, reply)
    end)
  end

  defp log_create(multi, post, space_user) do
    Multi.run(multi, :log, fn %{reply: reply} ->
      PostLog.insert(:reply_created, post, reply, space_user)
    end)
  end

  def record_view(multi, post, space_user) do
    Multi.run(multi, :post_view, fn %{reply: reply} ->
      Posts.record_view(post, space_user, reply)
    end)
  end

  defp after_transaction({:ok, %{reply: reply} = result}, post, author) do
    _ = subscribe_author(post, author)
    _ = subscribe_mentioned(post, result)

    {:ok, subscribers} = Posts.get_subscribers(post)

    _ = mark_unread_for_subscribers(post, reply, subscribers, author)
    _ = send_push_notifications(post, reply, subscribers, author)
    _ = send_events(post, result)

    {:ok, result}
  end

  defp after_transaction(err, _, _), do: err

  defp subscribe_author(post, author) do
    Posts.subscribe(author, [post])
  end

  defp subscribe_mentioned(post, %{mentions: mentioned_users}) do
    Enum.each(mentioned_users, fn mentioned_user ->
      Posts.subscribe(mentioned_user, [post])
    end)
  end

  defp mark_unread_for_subscribers(post, _reply, subscribers, author) do
    Enum.each(subscribers, fn subscriber ->
      # Skip marking unread for the author
      if subscriber.id !== author.id do
        _ = Posts.mark_as_unread(subscriber, [post])
      end
    end)
  end

  defp send_push_notifications(post, reply, subscribers, author) do
    present_user_ids =
      ("posts:" <> post.id)
      |> LevelWeb.Presence.list()
      |> Map.keys()
      |> MapSet.new()

    subscribed_user_ids =
      subscribers
      |> Enum.map(fn subscriber -> subscriber.user_id end)
      |> MapSet.new()

    notifiable_ids =
      present_user_ids
      |> MapSet.intersection(subscribed_user_ids)
      |> MapSet.delete(author.user_id)
      |> MapSet.to_list()

    subscription_map = Users.get_push_subscriptions(notifiable_ids)
    body = "@#{author.handle}: " <> reply.body
    payload = %Payload{body: body, tag: nil}

    subscription_map
    |> Map.values()
    |> List.flatten()
    |> Enum.each(fn subscription -> WebPush.send(payload, subscription) end)
  end

  defp send_events(post, %{reply: reply, mentions: mentioned_users}) do
    _ = Pubsub.reply_created(post.id, reply)

    Enum.each(mentioned_users, fn %SpaceUser{id: id} ->
      _ = Pubsub.user_mentioned(id, post)
    end)
  end
end
