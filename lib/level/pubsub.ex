defmodule Level.Pubsub do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  (such as Absinthe GraphQL subscriptions).
  """

  alias Level.Groups.Group
  alias Level.Groups.GroupUser
  alias Level.Posts.Post
  alias Level.Posts.Reply
  alias Level.Spaces.SpaceUser

  def publish(:space_user_updated, space_id, %SpaceUser{} = space_user) do
    do_publish(
      %{type: :space_user_updated, space_user: space_user},
      space_subscription: space_id
    )
  end

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

  def publish(:post_created, group_id, %Post{} = post) do
    do_publish(%{type: :post_created, post: post}, group_subscription: group_id)
  end

  def publish(:group_membership_updated, group_id, %GroupUser{} = group_user) do
    do_publish(
      %{type: :group_membership_updated, membership: group_user},
      group_subscription: group_id
    )
  end

  def publish(:group_updated, group_id, %Group{} = group) do
    do_publish(%{type: :group_updated, group: group}, group_subscription: group_id)
  end

  def publish(:reply_created, post_id, %Reply{} = reply) do
    do_publish(%{type: :reply_created, reply: reply}, post_subscription: post_id)
  end

  defp do_publish(payload, topics) do
    Absinthe.Subscription.publish(LevelWeb.Endpoint, payload, topics)
  end
end
