defmodule Level.Pubsub do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  (such as Absinthe GraphQL subscriptions).
  """

  alias Level.Groups.Group
  alias Level.Posts.Post
  alias Level.Posts.Reply
  alias Level.Spaces.Space
  alias Level.Spaces.SpaceUser

  # Space

  def publish(:space_updated, space_id, %Space{} = space) do
    do_publish(
      %{type: :space_updated, space: space},
      space_subscription: space_id
    )
  end

  def publish(:space_user_updated, space_id, %SpaceUser{} = space_user) do
    do_publish(
      %{type: :space_user_updated, space_user: space_user},
      space_subscription: space_id
    )
  end

  # Space user

  def publish(:group_bookmarked, space_user_id, %Group{} = group) do
    do_publish(
      %{type: :group_bookmarked, group: group},
      space_user_subscription: space_user_id
    )
  end

  def publish(:group_unbookmarked, space_user_id, %Group{} = group) do
    do_publish(
      %{type: :group_unbookmarked, group: group},
      space_user_subscription: space_user_id
    )
  end

  def publish(:post_subscribed, space_user_id, %Post{} = post) do
    do_publish(%{type: :post_subscribed, post: post}, space_user_subscription: space_user_id)
  end

  def publish(:post_unsubscribed, space_user_id, %Post{} = post) do
    do_publish(%{type: :post_unsubscribed, post: post}, space_user_subscription: space_user_id)
  end

  def publish(:posts_dismissed, space_user_id, posts) do
    do_publish(%{type: :posts_dismissed, posts: posts}, space_user_subscription: space_user_id)
  end

  def publish(:user_mentioned, space_user_id, %Post{} = post) do
    do_publish(%{type: :user_mentioned, post: post}, space_user_subscription: space_user_id)
  end

  def publish(:mentions_dismissed, space_user_id, %Post{} = post) do
    do_publish(%{type: :mentions_dismissed, post: post}, space_user_subscription: space_user_id)
  end

  # Group

  def publish(:post_created, group_id, %Post{} = post) do
    do_publish(%{type: :post_created, post: post}, group_subscription: group_id)
  end

  def publish(:group_membership_updated, group_id, {%Group{} = group, group_user}) do
    do_publish(
      %{type: :group_membership_updated, group: group, membership: group_user},
      group_subscription: group_id
    )
  end

  def publish(:group_updated, group_id, %Group{} = group) do
    do_publish(%{type: :group_updated, group: group}, group_subscription: group_id)
  end

  # Post

  def publish(:reply_created, post_id, %Reply{} = reply) do
    do_publish(%{type: :reply_created, reply: reply}, post_subscription: post_id)
  end

  defp do_publish(payload, topics) do
    Absinthe.Subscription.publish(LevelWeb.Endpoint, payload, topics)
  end
end
