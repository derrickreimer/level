defmodule LevelWeb.Schema.Subscriptions do
  @moduledoc false

  use Absinthe.Schema.Notation

  # Unions

  @desc "The payload for messages propagated to a user topic."
  union :user_subscription_payload do
    types [:space_joined_payload, :notification_created_payload, :notifications_dismissed_payload]
    resolve_type &type_resolver/2
  end

  @desc "The payload for messages propagated to a space topic."
  union :space_subscription_payload do
    types [:space_updated_payload, :space_user_updated_payload]
    resolve_type &type_resolver/2
  end

  @desc "The payload for messages propagated to a space user topic."
  union :space_user_subscription_payload do
    types [
      :group_created_payload,
      :group_updated_payload,
      :post_created_payload,
      :post_updated_payload,
      :reply_created_payload,
      :reply_updated_payload,
      :reply_deleted_payload,
      :post_closed_payload,
      :post_reopened_payload,
      :post_deleted_payload,
      :post_reaction_created_payload,
      :post_reaction_deleted_payload,
      :reply_reaction_created_payload,
      :reply_reaction_deleted_payload,
      :group_bookmarked_payload,
      :group_unbookmarked_payload,
      :posts_subscribed_payload,
      :posts_unsubscribed_payload,
      :posts_marked_as_unread_payload,
      :posts_marked_as_read_payload,
      :posts_dismissed_payload,
      :replies_viewed_payload
    ]

    resolve_type &type_resolver/2
  end

  @desc "The payload for messages propagated to a group topic."
  union :group_subscription_payload do
    types [
      :subscribed_to_group_payload,
      :watched_group_payload,
      :unsubscribed_from_group_payload
    ]

    resolve_type &type_resolver/2
  end

  # Objects

  @desc "The payload for the space joined event."
  object :space_joined_payload do
    @desc "The space."
    field :space, :space

    @desc "The space user."
    field :space_user, :space_user
  end

  @desc "The payload for the space updated event."
  object :space_updated_payload do
    @desc "The updated space."
    field :space, :space
  end

  @desc "The payload for the space user updated event."
  object :space_user_updated_payload do
    @desc "The updated space user."
    field :space_user, :space_user
  end

  @desc "The payload for the group updated event."
  object :group_updated_payload do
    @desc "The updated group."
    field :group, non_null(:group)
  end

  @desc "The payload for the group bookmarked event."
  object :group_bookmarked_payload do
    @desc "The bookmarked group."
    field :group, non_null(:group)
  end

  @desc "The payload for the group unbookmarked event."
  object :group_unbookmarked_payload do
    @desc "The unbookmarked group."
    field :group, non_null(:group)
  end

  @desc "The payload for the group created event."
  object :group_created_payload do
    @desc "The newly created group."
    field :group, :group
  end

  @desc "The payload for the post created event."
  object :post_created_payload do
    @desc "The newly created post."
    field :post, :post
  end

  @desc "The payload for the post updated event."
  object :post_updated_payload do
    @desc "The updated post."
    field :post, :post
  end

  @desc "The payload for the post closed event."
  object :post_closed_payload do
    @desc "The updated post."
    field :post, :post
  end

  @desc "The payload for the post reopened event."
  object :post_reopened_payload do
    @desc "The updated post."
    field :post, :post
  end

  @desc "The payload for the post deleted event."
  object :post_deleted_payload do
    @desc "The deleted post."
    field :post, :post
  end

  @desc "The payload for the posts subscribed event."
  object :posts_subscribed_payload do
    @desc "The subscribed posts."
    field :posts, list_of(:post)
  end

  @desc "The payload for the posts unsubscribed event."
  object :posts_unsubscribed_payload do
    @desc "The unsubscribed posts."
    field :posts, list_of(:post)
  end

  @desc "The payload for the posts marked as unread event."
  object :posts_marked_as_unread_payload do
    @desc "The posts marked as unread."
    field :posts, list_of(:post)
  end

  @desc "The payload for the posts marked as read event."
  object :posts_marked_as_read_payload do
    @desc "The posts marked as read."
    field :posts, list_of(:post)
  end

  @desc "The payload for the posts dismissed event."
  object :posts_dismissed_payload do
    @desc "The dismissed posts."
    field :posts, list_of(:post)
  end

  @desc "The payload for the replies viewed event."
  object :replies_viewed_payload do
    @desc "The viewed replies."
    field :replies, list_of(:reply)
  end

  @desc "The payload for the subscribed to group event."
  object :subscribed_to_group_payload do
    @desc "The group."
    field :group, non_null(:group)

    @desc "The space user."
    field :space_user, non_null(:space_user)
  end

  @desc "The payload for the watched group event."
  object :watched_group_payload do
    @desc "The group."
    field :group, non_null(:group)

    @desc "The space user."
    field :space_user, non_null(:space_user)
  end

  @desc "The payload for the unsubscribed from group event."
  object :unsubscribed_from_group_payload do
    @desc "The group."
    field :group, non_null(:group)

    @desc "The space user."
    field :space_user, non_null(:space_user)
  end

  @desc "The payload for the reply created event."
  object :reply_created_payload do
    @desc "The newly created reply."
    field :reply, :reply
  end

  @desc "The payload for the reply updated event."
  object :reply_updated_payload do
    @desc "The updated reply."
    field :reply, :reply
  end

  @desc "The payload for the reply deleted event."
  object :reply_deleted_payload do
    @desc "The deleted reply."
    field :reply, :reply
  end

  @desc "The payload for the post reaction created event."
  object :post_reaction_created_payload do
    @desc "The post."
    field :post, :post

    @desc "The reaction."
    field :reaction, :post_reaction
  end

  @desc "The payload for the post reaction deleted event."
  object :post_reaction_deleted_payload do
    @desc "The post."
    field :post, :post

    @desc "The reaction."
    field :reaction, :post_reaction
  end

  @desc "The payload for the reply reaction created event."
  object :reply_reaction_created_payload do
    @desc "The reply."
    field :reply, :reply

    @desc "The reaction."
    field :reaction, :reply_reaction
  end

  @desc "The payload for the reply reaction deleted event."
  object :reply_reaction_deleted_payload do
    @desc "The reply."
    field :reply, :reply

    @desc "The reaction."
    field :reaction, :reply_reaction
  end

  @desc "The payload for the notification created event."
  object :notification_created_payload do
    @desc "The notification."
    field :notification, :notification
  end

  @desc "The payload for the notification created event."
  object :notifications_dismissed_payload do
    @desc "The topic."
    field :topic, :string
  end

  defp type_resolver(%{type: type}, _) do
    type
    |> Atom.to_string()
    |> concat("_payload")
    |> String.to_atom()
  end

  defp concat(a, b) do
    a <> b
  end
end
