defmodule LevelWeb.Schema.Subscriptions do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "The payload for the group bookmark created event."
  object :group_bookmark_created_payload do
    @desc "The newly bookmarked group."
    field :group, :group
  end
end
