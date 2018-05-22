defmodule Level.Pubsub do
  @moduledoc """
  This module encapsulates behavior for publishing messages to listeners
  (such as Absinthe GraphQL subscriptions).
  """

  alias Level.Groups.Group
  alias Level.Posts.Post

  def publish(:group_bookmarked, space_user_id, %Group{} = group),
    do: do_publish(%{group: group}, group_bookmarked: space_user_id)

  def publish(:group_unbookmarked, space_user_id, %Group{} = group),
    do: do_publish(%{group: group}, group_unbookmarked: space_user_id)

  def publish(:post_created, space_user_id, %Post{} = post),
    do: do_publish(%{post: post}, post_created: space_user_id)

  defp do_publish(payload, topics) do
    Absinthe.Subscription.publish(LevelWeb.Endpoint, payload, topics)
  end
end
