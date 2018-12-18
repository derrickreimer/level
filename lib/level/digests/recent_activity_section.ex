defmodule Level.Digests.RecentActivitySection do
  @moduledoc """
  Builds a "recent activity" section for a digest.
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
  @spec build(Schemas.Digest.t(), SpaceUser.t(), Options.t()) :: {:ok, Section.t()} | :skip
  def build(digest, space_user, opts) do
    if has_data?(space_user, opts) do
      do_build(digest, space_user, opts)
    else
      :skip
    end
  end

  defp do_build(digest, space_user, opts) do
    post_count = get_post_count(space_user, opts.now)
    {summary, summary_html} = build_summary(post_count)

    link_url =
      main_url(
        LevelWeb.Endpoint,
        :index,
        [
          space_user.space.slug,
          "posts"
        ]
      )

    section_record =
      Persistence.insert_section!(digest, %{
        title: "Recent activity",
        summary: summary,
        summary_html: summary_html,
        link_text: "View my activity feed",
        link_url: link_url,
        rank: 2
      })

    compiled_posts =
      space_user
      |> get_highlighted_posts(opts.now)
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
      |> base_query(opts.now)
      |> limit(1)

    case Repo.all(query) do
      [] -> false
      _ -> true
    end
  end

  defp base_query(space_user, now) do
    space_user
    |> Posts.Query.base_query()
    |> Posts.Query.select_last_activity_at()
    |> Posts.Query.where_is_following_and_not_subscribed()
    |> Posts.Query.where_last_active_after(Timex.shift(now, hours: -24))
  end

  defp get_post_count(space_user, now) do
    space_user
    |> base_query(now)
    |> Posts.Query.count()
    |> Repo.one()
  end

  defp get_highlighted_posts(space_user, now) do
    inner_query = base_query(space_user, now)

    inner_query
    |> subquery()
    |> order_by(desc: :last_activity_at)
    |> limit(20)
    |> Repo.all()
  end

  defp build_summary(0) do
    text = "There hasn't been any activity in the past day."
    html = "There hasn&rsquo;t been any activity in the past day."
    {text, html}
  end

  defp build_summary(_count) do
    text = "Here are some messages posted recently in your groups."
    html = "Here are some messages posted recently in your groups."
    {text, html}
  end
end
