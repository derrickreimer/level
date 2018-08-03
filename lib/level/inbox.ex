defmodule Level.Inbox do
  @moduledoc """
  This module is responsible for generating inbox feeds.
  """

  import Ecto.Query, warn: false

  alias Level.Groups.GroupUser
  alias Level.Posts.PostLog
  alias Level.Posts.PostUser
  alias Level.Spaces.SpaceUser

  @doc """
  Builds a query for fetching post log entries for groups that the given
  user is subscribed to.
  """
  @spec group_activity_query(SpaceUser.t()) :: Ecto.Query.t()
  def group_activity_query(%SpaceUser{id: space_user_id}) do
    from pl in PostLog,
      join: gu in GroupUser,
      on: gu.group_id == pl.group_id,
      where: gu.space_user_id == ^space_user_id
  end

  @doc """
  Builds a query for fetching post log entries for posts that the given
  user is subscribed to.
  """
  @spec post_activity_query(SpaceUser.t()) :: Ecto.Query.t()
  def post_activity_query(%SpaceUser{id: space_user_id}) do
    from pl in PostLog,
      join: pu in PostUser,
      on: pu.post_id == pl.post_id,
      where: pu.space_user_id == ^space_user_id and pu.subscription_state == "SUBSCRIBED"
  end
end
