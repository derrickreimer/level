defmodule Level.Digests do
  @moduledoc """
  The Digests context.
  """

  import Ecto.Query
  import Level.Gettext
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
  Fetches a digest.
  """
  def get_digest(%SpaceUser{id: space_user_id}, id) do
    query =
      from d in Schemas.Digest,
        where: d.space_user_id == ^space_user_id and d.id == ^id,
        preload: [digest_sections: [digest_posts: :post]]

    query
    |> Repo.one()
    |> after_get_digest()
  end

  defp after_get_digest(%Schemas.Digest{} = digest) do
    assembled_digest =
      digest
      |> assemble_digest(assemble_sections(digest.digest_sections))

    {:ok, assembled_digest}
  end

  defp after_get_digest(_), do: {:error, dgettext("errors", "Digest not found")}

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
      |> Repo.preload(:user)

    Multi.new()
    |> persist_digest(space_user, opts)
    |> persist_sections(space_user, opts)
    |> Repo.transaction()
    |> after_build()
  end

  @doc """
  Sends a compiled digest email.
  """
  def send_email(%Digest{} = digest) do
    digest
    |> Email.digest()
    |> Mailer.deliver_now()
  end

  defp persist_digest(multi, space_user, opts) do
    params = %{
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      title: opts.title,
      subject: opts.title,
      to_email: space_user.user.email,
      start_at: opts.start_at,
      end_at: opts.end_at
    }

    changeset =
      %Schemas.Digest{}
      |> Schemas.Digest.create_changeset(params)

    Multi.insert(multi, :digest, changeset)
  end

  defp persist_sections(multi, space_user, opts) do
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

    assembled_posts =
      space_user
      |> highlighted_inbox_posts()
      |> assemble_posts()

    insert_posts!(digest, section_record, assembled_posts)
    section = assemble_section(section_record, assembled_posts)
    [section | sections]
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

  defp after_build({:ok, data}) do
    {:ok, assemble_digest(data.digest, data.sections)}
  end

  defp after_build(_) do
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

  defp insert_posts!(digest, section, posts) do
    posts
    |> Enum.with_index()
    |> Enum.map(fn {post, rank} ->
      insert_post!(digest, section, post, rank)
    end)
  end

  defp insert_post!(digest, section, post, rank) do
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

  # Functions for mapping persisted data to the Digest data structure

  @spec assemble_digest(Schemas.Digest.t(), [Section.t()]) :: Digest.t()
  defp assemble_digest(digest, assembled_sections) do
    %Digest{
      id: digest.id,
      title: digest.title,
      subject: digest.subject,
      to_email: digest.to_email,
      sections: assembled_sections,
      start_at: digest.start_at,
      end_at: digest.end_at
    }
  end

  @spec assemble_sections([Schemas.DigestSection.t()]) :: [Section.t()]
  defp assemble_sections(sections) do
    Enum.map(sections, &assemble_section/1)
  end

  @spec assemble_section(Schemas.DigestSection.t()) :: Section.t()
  defp assemble_section(section) do
    posts = Enum.map(section.digest_posts, fn digest_post -> digest_post.post end)

    %Section{
      title: section.title,
      summary: section.summary,
      summary_html: section.summary_html,
      link_text: section.link_text,
      link_url: section.link_url,
      posts: assemble_posts(posts)
    }
  end

  @spec assemble_section(Schemas.DigestSection.t(), [Post.t()]) :: Section.t()
  defp assemble_section(section, assembled_posts) do
    %Section{
      title: section.title,
      summary: section.summary,
      summary_html: section.summary_html,
      link_text: section.link_text,
      link_url: section.link_url,
      posts: assembled_posts
    }
  end

  @spec assemble_posts([Schemas.Post.t()]) :: [Post.t()]
  defp assemble_posts(posts) do
    Enum.map(posts, &assemble_post/1)
  end

  @spec assemble_post(Schemas.Post.t()) :: Post.t()
  defp assemble_post(post) do
    Post.build(post)
  end
end
