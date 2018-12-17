defmodule Level.Digests.UnreadToday do
  @moduledoc """
  Builds an "unread today" section for a digest.
  """

  import Ecto.Query
  import LevelWeb.Router.Helpers

  alias Level.Digests.Compiler
  alias Level.Digests.Persistence
  alias Level.Digests.Section
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas
  alias Level.Schemas.SpaceUser

  @doc """
  Builds a digest section.
  """
  @spec build(Schemas.Digest.t(), SpaceUser.t(), Options.t()) :: {:ok, Section.t()}
  def build(digest, space_user, opts) do
    unread_count = get_unread_count(space_user, opts.now)
    {summary, summary_html} = build_summary(unread_count)

    link_url =
      main_url(
        LevelWeb.Endpoint,
        :index,
        [
          space_user.space.slug,
          "inbox"
        ],
        last_activity: "today"
      )

    section_record =
      Persistence.insert_section!(digest, %{
        title: "Unread Today",
        summary: summary,
        summary_html: summary_html,
        link_text: "View today's posts",
        link_url: link_url,
        rank: 1
      })

    compiled_posts =
      space_user
      |> get_highlighted_inbox_posts(opts.now)
      |> Compiler.compile_posts()

    Persistence.insert_posts!(digest, section_record, compiled_posts)
    section = Compiler.compile_section(section_record, compiled_posts)
    {:ok, section}
  end

  @doc """
  Determines if the section has any interesting data to report.
  """
  @spec has_data?(SpaceUser.t(), Options.t()) :: boolean()
  def has_data?(space_user, opts) do
    query =
      space_user
      |> Posts.Query.base_query()
      |> Posts.Query.select_last_activity_at()
      |> Posts.Query.where_unread_in_inbox()
      |> Posts.Query.where_last_active_today(opts.now)
      |> limit(1)

    case Repo.all(query) do
      [] -> false
      _ -> true
    end
  end

  defp get_unread_count(space_user, now) do
    space_user
    |> Posts.Query.base_query()
    |> Posts.Query.select_last_activity_at()
    |> Posts.Query.where_unread_in_inbox()
    |> Posts.Query.where_last_active_today(now)
    |> Posts.Query.count()
    |> Repo.one()
  end

  defp get_highlighted_inbox_posts(space_user, now) do
    inner_query =
      space_user
      |> Posts.Query.base_query()
      |> Posts.Query.select_last_activity_at()
      |> Posts.Query.where_unread_in_inbox()
      |> Posts.Query.where_last_active_today(now)

    inner_query
    |> subquery()
    |> order_by(desc: :last_activity_at)
    |> limit(20)
    |> Repo.all()
  end

  defp build_summary(0) do
    text = "You're all caught up! You have no unread posts in your inbox."
    html = "You&rsquo;re all caught up! You have no unread posts in your inbox."
    {text, html}
  end

  defp build_summary(unread_count) do
    unread_phrase = pluralize(unread_count, "unread post", "unread posts")
    text = "You have #{unread_phrase} from today in your inbox."
    html = "You have <strong>#{unread_phrase}</strong> in your inbox."

    {text, html}
  end

  defp pluralize(count, singular, plural) do
    if count == 1 do
      "#{count} #{singular}"
    else
      "#{count} #{plural}"
    end
  end
end
