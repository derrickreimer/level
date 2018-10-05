defmodule LevelWeb.Schema.Subscriptions do
  @moduledoc false

  use Absinthe.Schema.Notation

  # Unions

  @desc "The payload for messages propagated to a space topic."
  union :space_subscription_payload do
    types [:space_updated_payload, :space_user_updated_payload]
    resolve_type &type_resolver/2
  end

  @desc "The payload for messages propagated to a space user topic."
  union :space_user_subscription_payload do
    types [
      :group_bookmarked_payload,
      :group_unbookmarked_payload,
      :posts_subscribed_payload,
      :posts_unsubscribed_payload,
      :posts_marked_as_unread_payload,
      :posts_marked_as_read_payload,
      :posts_dismissed_payload,
      :user_mentioned_payload,
      :mentions_dismissed_payload,
      :replies_viewed_payload
    ]

    resolve_type &type_resolver/2
  end

  @desc "The payload for messages propagated to a group topic."
  union :group_subscription_payload do
    types [:group_updated_payload, :post_created_payload, :group_membership_updated_payload]
    resolve_type &type_resolver/2
  end

  @desc "The payload for messages propagated to a post topic."
  union :post_subscription_payload do
    types [:post_updated_payload, :reply_created_payload, :reply_updated_payload]
    resolve_type &type_resolver/2
  end

  # Objects

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

  @desc "The payload for the group membership updated event."
  object :group_membership_updated_payload do
    @desc "The updated membership."
    field :membership, :group_membership

    @desc "The group."
    field :group, non_null(:group)
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

  @desc "The payload for the mentioned dismissed event."
  object :mentions_dismissed_payload do
    @desc "The post."
    field :post, :post
  end

  @desc "The payload for the user mentioned event."
  object :user_mentioned_payload do
    @desc "The post."
    field :post, :post
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
