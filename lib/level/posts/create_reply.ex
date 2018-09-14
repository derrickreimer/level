defmodule Level.Posts.CreateReply do
  @moduledoc """
  Responsible for creating a reply to post.
  """

  alias Ecto.Multi
  alias Level.Mentions
  alias Level.Posts
  alias Level.Posts.Post
  alias Level.Posts.PostLog
  alias Level.Posts.Reply
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Users
  alias Level.WebPush

  @typedoc "Dependencies injected in the perform function"
  @type options :: %{
          presence: any(),
          web_push: any(),
          pubsub: any()
        }

  @typedoc "The result of calling the perform function"
  @type result :: {:ok, map()} | {:error, any(), any(), map()}

  @doc """
  Adds a reply to post.
  """
  @spec perform(SpaceUser.t(), Post.t(), map(), options()) :: result()
  def perform(%SpaceUser{} = author, %Post{} = post, params, opts) do
    Multi.new()
    |> do_insert(build_params(author, post, params))
    |> record_mentions(post)
    |> log_create(post, author)
    |> record_view(post, author)
    |> Repo.transaction()
    |> after_transaction(post, author, opts)
  end

  @doc """
  Builds a payload for a push notifications.
  """
  @spec build_push_payload(Reply.t(), SpaceUser.t()) :: WebPush.Payload.t()
  def build_push_payload(%Reply{} = reply, %SpaceUser{} = author) do
    body = "@#{author.handle}: " <> reply.body
    %WebPush.Payload{body: body, tag: nil}
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

  defp after_transaction({:ok, %{reply: reply} = result}, post, author, opts) do
    _ = subscribe_author(post, author)
    _ = subscribe_mentioned(post, result)

    {:ok, subscribers} = Posts.get_subscribers(post)

    _ = mark_unread_for_subscribers(post, reply, subscribers, author)
    _ = send_push_notifications(post, reply, subscribers, author, opts)
    _ = send_events(post, result, opts)

    {:ok, result}
  end

  defp after_transaction(err, _, _, _), do: err

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

  defp send_push_notifications(post, reply, subscribers, author, %{
         presence: presence,
         web_push: web_push
       }) do
    present_user_ids =
      ("posts:" <> post.id)
      |> presence.list()
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
    payload = build_push_payload(reply, author)

    subscription_map
    |> Map.values()
    |> List.flatten()
    |> Enum.each(fn subscription -> web_push.send_web_push(payload, subscription) end)
  end

  defp send_events(post, %{reply: reply, mentions: mentioned_users}, %{pubsub: pubsub}) do
    _ = pubsub.reply_created(post.id, reply)

    Enum.each(mentioned_users, fn %SpaceUser{id: id} ->
      _ = pubsub.user_mentioned(id, post)
    end)
  end
end
