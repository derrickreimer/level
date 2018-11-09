defmodule Level.Digests do
  @moduledoc """
  The Digests context.
  """

  require Ecto.Query

  import LevelWeb.Router.Helpers

  alias Ecto.Multi
  alias Level.Digests.Digest
  alias Level.Digests.Post
  alias Level.Digests.Section
  alias Level.Email
  alias Level.Mailer
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas
  alias Level.Schemas
  alias Level.Schemas.SpaceUser

  @typedoc "An Olsen time zone"
  @type time_zone :: String.t()

  @typedoc "Options for building a digest"
  @type opts :: %{
          title: String.t(),
          start_at: NaiveDateTime.t(),
          end_at: NaiveDateTime.t()
        }

  @doc """
  Builds options for the daily digest.
  """
  @spec daily_opts(DateTime.t()) :: {:ok, opts()} | {:error, term()}
  def daily_opts(end_at) do
    case Timex.shift(end_at, hours: -24) do
      {:error, term} ->
        {:error, term}

      start_at ->
        opts = %{
          title: "Your Daily Digest",
          start_at: start_at,
          end_at: end_at
        }

        {:ok, opts}
    end
  end

  @doc """
  Builds a digest for the given user.
  """
  @spec build(SpaceUser.t(), opts()) :: {:ok, Digest.t()} | {:error, String.t()}
  def build(%SpaceUser{} = space_user, opts) do
    space_user =
      space_user
      |> Repo.preload(:space)

    Multi.new()
    |> insert_digest(space_user, opts)
    |> insert_sections(space_user, opts)
    |> Repo.transaction()
    |> assemble_digest(space_user)
  end

  @doc """
  Sends a compiled digest email.
  """
  def send_email(%Digest{} = digest) do
    digest
    |> Email.digest()
    |> Mailer.deliver_now()
  end

  defp insert_digest(multi, space_user, opts) do
    params = %{
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      title: opts.title,
      start_at: opts.start_at,
      end_at: opts.end_at
    }

    changeset =
      %Schemas.Digest{}
      |> Schemas.Digest.create_changeset(params)

    Multi.insert(multi, :digest, changeset)
  end

  defp insert_sections(multi, space_user, opts) do
    Multi.run(multi, :sections, fn %{digest: digest} ->
      sections =
        []
        |> build_inbox_section(digest, space_user, opts)

      {:ok, sections}
    end)
  end

  defp build_inbox_section(sections, digest, space_user, _opts) do
    unreads = unread_inbox_count(space_user)
    unread_snippet = pluralize(unreads, "unread post", "unread posts")
    summary = "You have #{unread_snippet} in your inbox."
    summary_html = "You have <strong>#{unread_snippet}</strong> in your inbox."

    link_url =
      main_url(LevelWeb.Endpoint, :index, [
        space_user.space.slug,
        "inbox"
      ])

    section_record =
      insert_section!(digest, %{
        title: "Inbox Highlights",
        summary: summary,
        summary_html: summary_html,
        link_text: "View my inbox",
        link_url: link_url,
        rank: 1
      })

    posts =
      space_user
      |> highlighted_inbox_posts()
      |> assemble_posts()

    insert_post_snapshots!(digest, section_record, posts)

    section = %Section{
      title: section_record.title,
      summary: section_record.summary,
      summary_html: section_record.summary_html,
      link_text: section_record.link_text,
      link_url: section_record.link_url,
      posts: posts
    }

    [section | sections]
  end

  defp assemble_posts(posts) do
    Enum.map(posts, fn post -> Post.build(post) end)
  end

  defp unread_inbox_count(space_user) do
    space_user
    |> Posts.Query.base_query()
    |> Posts.Query.where_unread_in_inbox()
    |> Posts.Query.count()
    |> Repo.one()
  end

  defp highlighted_inbox_posts(space_user) do
    space_user
    |> Posts.Query.base_query()
    |> Posts.Query.where_undismissed_in_inbox()
    |> Posts.Query.select_last_activity_at()
    |> Ecto.Query.limit(5)
    |> Repo.all()
  end

  defp assemble_digest({:ok, data}, space_user) do
    space_user =
      space_user
      |> Repo.preload(:user)

    digest = %Digest{
      id: data.digest.id,
      title: data.digest.title,
      subject: data.digest.title,
      to_email: space_user.user.email,
      sections: data.sections,
      start_at: data.digest.start_at,
      end_at: data.digest.end_at
    }

    {:ok, digest}
  end

  defp assemble_digest(_, _) do
    {:error, "An unexpected error occurred"}
  end

  defp pluralize(count, singular, plural) do
    if count == 1 do
      "#{count} #{singular}"
    else
      "#{count} #{plural}"
    end
  end

  # Private persistence functions

  defp insert_section!(digest, params) do
    params =
      Map.merge(params, %{
        space_id: digest.space_id,
        digest_id: digest.id
      })

    %Schemas.DigestSection{}
    |> Schemas.DigestSection.create_changeset(params)
    |> Repo.insert!()
  end

  defp insert_post_snapshots!(digest, section, posts) do
    posts
    |> Enum.with_index()
    |> Enum.map(fn {post, rank} ->
      insert_post_snapshot!(digest, section, post, rank)
    end)
  end

  defp insert_post_snapshot!(digest, section, post, rank) do
    params = %{
      space_id: digest.space_id,
      digest_id: digest.id,
      digest_section_id: section.id,
      post_id: post.id,
      rank: rank
    }

    %Schemas.DigestPost{}
    |> Schemas.DigestPost.create_changeset(params)
    |> Repo.insert!()
  end
end
