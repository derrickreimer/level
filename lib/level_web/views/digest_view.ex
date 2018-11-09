defmodule LevelWeb.DigestView do
  @moduledoc false

  use LevelWeb, :view

  alias Level.AssetStore
  alias Level.Digests.Post
  alias Level.Posts
  alias Level.Schemas.Reply
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  def display_name(%SpaceBot{display_name: display_name}), do: display_name

  def display_name(%SpaceUser{} = space_user) do
    SpaceUser.display_name(space_user)
  end

  def timestamp(%Post{} = post) do
    Timex.format!(post.posted_at, "{Mshort} {D} at {h12}:{m} {am}")
  end

  def reply_author(%Reply{} = reply) do
    reply.space_bot || reply.space_user
  end

  def has_avatar?(user_or_bot) do
    !is_nil(user_or_bot.avatar)
  end

  def avatar_url(user_or_bot) do
    AssetStore.avatar_url(user_or_bot.avatar)
  end

  def render_body(%Post{} = post) do
    {:ok, rendered_body} = Posts.render_body(post.body)
    raw(rendered_body)
  end

  def render_body(%Reply{} = reply) do
    {:ok, rendered_body} = Posts.render_body(reply.body)
    raw(rendered_body)
  end
end
