defmodule LevelWeb.DigestView do
  @moduledoc false

  use LevelWeb, :view

  alias Level.AssetStore
  alias Level.Digests.Digest
  alias Level.Digests.Post
  alias Level.Digests.Reply
  alias Level.Posts
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser

  def display_name(%SpaceUser{} = space_user) do
    SpaceUser.display_name(space_user)
  end

  def display_name(%SpaceBot{display_name: bot_display_name}) do
    bot_display_name
  end

  def display_name(%Post{} = post, %SpaceBot{display_name: bot_display_name}) do
    post.display_name || bot_display_name
  end

  def display_name(%Post{} = post, %SpaceUser{} = space_user) do
    post.display_name || SpaceUser.display_name(space_user)
  end

  def display_name(%Reply{}, %SpaceBot{display_name: bot_display_name}) do
    bot_display_name
  end

  def display_name(%Reply{}, %SpaceUser{} = space_user) do
    SpaceUser.display_name(space_user)
  end

  def digest_date(%Digest{} = digest) do
    digest.end_at
    |> in_time_zone(digest.time_zone)
    |> Timex.format!("{WDfull}, {Mfull} {D}, {YYYY}")
  end

  def digest_time(%Digest{} = digest) do
    digest.end_at
    |> in_time_zone(digest.time_zone)
    |> Timex.format!("{h12}:{m} {am}")
  end

  def post_timestamp(digest, post) do
    post.posted_at
    |> in_time_zone(digest.time_zone)
    |> Timex.format!("{Mshort} {D} at {h12}:{m} {am}")
  end

  def reply_author(%Reply{} = reply) do
    reply.author
  end

  def groups_label(groups) do
    groups
    |> Enum.map(fn group -> "##{group.name}" end)
    |> Enum.sort()
    |> Enum.join(" ")
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

  def render_body(%Space{} = space, %Post{} = post) do
    {:ok, rendered_body} = Posts.render_body(post.body, %{space: space, absolute: true})
    raw(rendered_body)
  end

  def render_body(%Space{} = space, %Reply{} = reply) do
    {:ok, rendered_body} = Posts.render_body(reply.body, %{space: space, absolute: true})
    raw(rendered_body)
  end

  def in_time_zone(date, tz) do
    case Timex.Timezone.convert(date, tz) do
      {:error, _} -> date
      converted_date -> converted_date
    end
  end
end
