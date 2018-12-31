defmodule Level.Digests.InboxSection do
  @moduledoc """
  Builds an Inbox Highlights section for a digest.
  """

  import Ecto.Query
  import LevelWeb.Router.Helpers

  alias Level.Digests.Compiler
  alias Level.Digests.Options
  alias Level.Digests.Persistence
  alias Level.Digests.Section
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas
  alias Level.Schemas.SpaceUser

  @behaviour Section

  @doc """
  Builds a digest section.
  """
  @impl Section
  @spec build(Schemas.Digest.t(), SpaceUser.t(), Options.t()) :: {:ok, Section.t()}
  def build(digest, space_user, _opts) do
    unread_count = get_unread_count(space_user)
    read_count = get_read_count(space_user)
    {summary, summary_html} = build_summary(unread_count, read_count)

    link_url =
      main_url(LevelWeb.Endpoint, :index, [
        space_user.space.slug,
        "inbox"
      ])

    section_record =
      Persistence.insert_section!(digest, %{
        title: "Inbox Highlights",
        summary: summary,
        summary_html: summary_html,
        link_text: "View my Inbox",
        link_url: link_url,
        rank: 1
      })

    compiled_posts =
      space_user
      |> get_highlighted_posts()
      |> Compiler.compile_posts()

    Persistence.insert_posts!(digest, section_record, compiled_posts)
    section = Compiler.compile_section(section_record, compiled_posts)
    {:ok, section}
  end

  @doc """
  Determines if the section has any interesting data to report.
  """
  @impl Section
  @spec has_data?(SpaceUser.t(), Options.t()) :: boolean()
  def has_data?(space_user, opts) do
    query =
      space_user
      |> Posts.Query.base_query()
      |> Posts.Query.select_last_activity_at()
      |> Posts.Query.where_undismissed_in_inbox()
      |> Posts.Query.where_last_active_after(Timex.shift(opts.now, hours: -24))
      |> limit(1)

    case Repo.all(query) do
      [] -> false
      _ -> true
    end
  end

  defp get_unread_count(space_user) do
    space_user
    |> Posts.Query.base_query()
    |> Posts.Query.where_unread_in_inbox()
    |> Posts.Query.count()
    |> Repo.one()
  end

  defp get_read_count(space_user) do
    space_user
    |> Posts.Query.base_query()
    |> Posts.Query.where_read_in_inbox()
    |> Posts.Query.count()
    |> Repo.one()
  end

  defp get_highlighted_posts(space_user) do
    inner_query =
      space_user
      |> Posts.Query.base_query()
      |> Posts.Query.where_undismissed_in_inbox()
      |> Posts.Query.select_last_activity_at()

    inner_query
    |> subquery()
    |> order_by(desc: :last_activity_at)
    |> limit(5)
    |> Repo.all()
  end

  defp build_summary(0, 0) do
    text = "Congratulations! You've achieved Inbox Zero."
    html = "Congratulations! You&rsquo;ve achieved Inbox Zero."
    {text, html}
  end

  defp build_summary(unread_count, 0) do
    unread_phrase = pluralize(unread_count, "unread post", "unread posts")
    text = "You have #{unread_phrase} in your inbox."
    html = "You have <strong>#{unread_phrase}</strong> in your inbox."

    {text, html}
  end

  defp build_summary(0, read_count) do
    read_phrase = pluralize(read_count, "post", "posts")

    text =
      "You have #{read_phrase} in your inbox. " <>
        "We recommend dismissing posts from your inbox once you are finished with them."

    html =
      "You have <strong>#{read_phrase}</strong> in your inbox. " <>
        "We recommend dismissing posts from your inbox once you are finished with them."

    {text, html}
  end

  defp build_summary(unread_count, read_count) do
    unread_phrase = pluralize(unread_count, "unread post", "unread posts")
    read_phrase = pluralize(read_count, "post", "posts")

    plaintext =
      "You have #{unread_phrase} and " <> "#{read_phrase} you have already seen in your inbox."

    html =
      "You have <strong>#{unread_phrase}</strong> and " <>
        "#{read_phrase} you have already seen in your inbox."

    {plaintext, html}
  end

  defp pluralize(count, singular, plural) do
    if count == 1 do
      "#{count} #{singular}"
    else
      "#{count} #{plural}"
    end
  end
end
