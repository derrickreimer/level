defmodule Level.Events do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  (such as Absinthe GraphQL subscriptions).
  """

  alias Level.Schemas.Group
  alias Level.Schemas.Post
  alias Level.Schemas.PostReaction
  alias Level.Schemas.Reply
  alias Level.Schemas.ReplyReaction
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  # User

  def space_joined(id, %Space{} = space, %SpaceUser{} = space_user) do
    publish_to_user(id, :space_joined, %{space: space, space_user: space_user})
  end

  def notification_created(id, notification) do
    publish_to_user(id, :notification_created, %{notification: notification})
  end

  def notification_dismissed(id, notification) do
    publish_to_user(id, :notification_dismissed, %{notification: notification})
  end

  def notifications_dismissed(id, topic) do
    publish_to_user(id, :notifications_dismissed, %{topic: topic})
  end

  # Space

  def space_updated(id, %Space{} = space) do
    publish_to_space(id, :space_updated, %{space: space})
  end

  def space_user_updated(id, %SpaceUser{} = space_user) do
    publish_to_space(id, :space_user_updated, %{space_user: space_user})
  end

  # Space user

  def group_created(ids, %Group{} = group) do
    publish_to_many_space_users(ids, :group_created, %{group: group})
  end

  def group_updated(ids, %Group{} = group) do
    publish_to_many_space_users(ids, :group_updated, %{group: group})
  end

  def post_created(ids, %Post{} = post) do
    publish_to_many_space_users(ids, :post_created, %{post: post})
  end

  def post_updated(ids, %Post{} = post) do
    publish_to_many_space_users(ids, :post_updated, %{post: post})
  end

  def reply_created(ids, %Reply{} = reply) do
    publish_to_many_space_users(ids, :reply_created, %{reply: reply})
  end

  def reply_updated(ids, %Reply{} = reply) do
    publish_to_many_space_users(ids, :reply_updated, %{reply: reply})
  end

  def reply_deleted(ids, %Reply{} = reply) do
    publish_to_many_space_users(ids, :reply_deleted, %{reply: reply})
  end

  def post_closed(ids, %Post{} = post) do
    publish_to_many_space_users(ids, :post_closed, %{post: post})
  end

  def post_reopened(ids, %Post{} = post) do
    publish_to_many_space_users(ids, :post_reopened, %{post: post})
  end

  def post_deleted(ids, %Post{} = post) do
    publish_to_many_space_users(ids, :post_deleted, %{post: post})
  end

  def post_reaction_created(ids, %Post{} = post, %PostReaction{} = reaction) do
    publish_to_many_space_users(ids, :post_reaction_created, %{post: post, reaction: reaction})
  end

  def post_reaction_deleted(ids, %Post{} = post, %PostReaction{} = reaction) do
    publish_to_many_space_users(ids, :post_reaction_deleted, %{post: post, reaction: reaction})
  end

  def reply_reaction_created(ids, %Reply{} = reply, %ReplyReaction{} = reaction) do
    publish_to_many_space_users(ids, :reply_reaction_created, %{reply: reply, reaction: reaction})
  end

  def reply_reaction_deleted(ids, %Reply{} = reply, %ReplyReaction{} = reaction) do
    publish_to_many_space_users(ids, :reply_reaction_deleted, %{reply: reply, reaction: reaction})
  end

  def group_bookmarked(id, %Group{} = group) do
    publish_to_space_user(id, :group_bookmarked, %{group: group})
  end

  def group_unbookmarked(id, %Group{} = group) do
    publish_to_space_user(id, :group_unbookmarked, %{group: group})
  end

  def posts_subscribed(id, posts) do
    publish_to_space_user(id, :posts_subscribed, %{posts: posts})
  end

  def posts_unsubscribed(id, posts) do
    publish_to_space_user(id, :posts_unsubscribed, %{posts: posts})
  end

  def posts_marked_as_unread(id, posts) do
    publish_to_space_user(id, :posts_marked_as_unread, %{posts: posts})
  end

  def posts_marked_as_read(id, posts) do
    publish_to_space_user(id, :posts_marked_as_read, %{posts: posts})
  end

  def posts_dismissed(id, posts) do
    publish_to_space_user(id, :posts_dismissed, %{posts: posts})
  end

  def replies_viewed(id, replies) do
    publish_to_space_user(id, :replies_viewed, %{replies: replies})
  end

  # Group

  def group_membership_updated(id, {%Group{} = group, group_user}) do
    publish_to_group(id, :group_membership_updated, %{group: group, membership: group_user})
  end

  def subscribed_to_group(id, %Group{} = group, %SpaceUser{} = space_user) do
    publish_to_group(id, :subscribed_to_group, %{group: group, space_user: space_user})
  end

  def watched_group(id, %Group{} = group, %SpaceUser{} = space_user) do
    publish_to_group(id, :watched_group, %{group: group, space_user: space_user})
  end

  def unsubscribed_from_group(id, %Group{} = group, %SpaceUser{} = space_user) do
    publish_to_group(id, :unsubscribed_from_group, %{group: group, space_user: space_user})
  end

  # Internal

  defp publish_to_user(id, type, data) do
    do_publish(Map.merge(data, %{type: type}), user_subscription: id)
  end

  defp publish_to_space(id, type, data) do
    do_publish(Map.merge(data, %{type: type}), space_subscription: id)
  end

  defp publish_to_space_user(id, type, data) do
    do_publish(Map.merge(data, %{type: type}), space_user_subscription: id)
  end

  defp publish_to_many_space_users(ids, type, data) do
    topics = Enum.map(ids, fn id -> {:space_user_subscription, id} end)
    do_publish(Map.merge(data, %{type: type}), topics)
  end

  defp publish_to_group(id, type, data) do
    do_publish(Map.merge(data, %{type: type}), group_subscription: id)
  end

  defp do_publish(payload, topics) do
    Absinthe.Subscription.publish(LevelWeb.Endpoint, payload, topics)
  end
end
