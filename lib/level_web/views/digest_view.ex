defmodule LevelWeb.DigestView do
  @moduledoc false

  use LevelWeb, :view

  alias Level.AssetStore
  alias Level.Digests.Digest
  alias Level.Digests.Post
  alias Level.Posts
  alias Level.Schemas.Reply
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  def display_name(%SpaceBot{display_name: display_name}), do: display_name

  def display_name(%SpaceUser{} = space_user) do
    SpaceUser.display_name(space_user)
  end

  def digest_date(%Digest{} = digest) do
    Timex.format!(digest.end_at, "{WDfull}, {Mfull} {D}, {YYYY}")
  end

  def digest_time(%Digest{} = digest) do
    Timex.format!(digest.end_at, "{h12}:{m} {am}")
  end

  def post_timestamp(%Post{} = post) do
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

  def avatar(user_or_bot) do
    if has_avatar?(user_or_bot) do
      raw(~s(<img src="#{avatar_url(user_or_bot)}" alt="Author" class="avatar" />))
    else
      initial =
        user_or_bot
        |> display_name()
        |> String.first()

      raw(~s{
        <table class="w-32px h-32px cell-0" width="32" height="32" cellpadding="0" cellspacing="0">
          <tr>
            <td class="texitar" width="32" height="32">
              #{initial}
            </td>
          </tr>
        </table>
      })
    end
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
