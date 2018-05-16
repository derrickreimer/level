defmodule LevelWeb.Schema.Subscriptions do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "The payload for the group bookmarked event."
  object :group_bookmarked_payload do
    @desc "The newly bookmarked group."
    field :group, :group
  end
end
