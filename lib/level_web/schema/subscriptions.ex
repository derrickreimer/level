defmodule LevelWeb.Schema.Subscriptions do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "The payload for the group bookmarked event."
  object :group_bookmarked_payload do
    @desc "The bookmarked group."
    field :group, :group
  end

  @desc "The payload for the group unbookmarked event."
  object :group_unbookmarked_payload do
    @desc "The unbookmarked group."
    field :group, :group
  end

  @desc "The payload for the post created event."
  object :post_created_payload do
    @desc "The newly created post."
    field :post, :post
  end
end
