defmodule LevelWeb.Schema.Subscriptions do
  @moduledoc false

  use Absinthe.Schema.Notation

  # Unions

  @desc "The payload for messages propagated to a space topic."
  union :space_subscription_payload do
    types [:space_updated_payload, :space_user_updated_payload]

    resolve_type fn
      %{type: :space_updated}, _ -> :space_updated_payload
      %{type: :space_user_updated}, _ -> :space_user_updated_payload
    end
  end

  @desc "The payload for messages propagated to a space user topic."
  union :space_user_subscription_payload do
    types [:group_bookmarked_payload, :group_unbookmarked_payload]

    resolve_type fn
      %{type: :group_bookmarked}, _ -> :group_bookmarked_payload
      %{type: :group_unbookmarked}, _ -> :group_unbookmarked_payload
    end
  end

  @desc "The payload for messages propagated to a group topic."
  union :group_subscription_payload do
    types [:group_updated_payload, :post_created_payload, :group_membership_updated_payload]

    resolve_type fn
      %{type: :group_updated}, _ -> :group_updated_payload
      %{type: :post_created}, _ -> :post_created_payload
      %{type: :group_membership_updated}, _ -> :group_membership_updated_payload
    end
  end

  @desc "The payload for messages propagated to a post topic."
  union :post_subscription_payload do
    types [:reply_created_payload]
    resolve_type fn %{type: :reply_created}, _ -> :reply_created_payload end
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
end
