defmodule Level.Digests do
  @moduledoc """
  The Digests context.
  """

  alias Ecto.Multi
  alias Level.Digests.Digest
  alias Level.Digests.Section
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
    Multi.new()
    |> insert_digest(space_user, opts)
    |> insert_sections(space_user, opts)
    |> Repo.transaction()
    |> assemble_digest()
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

    section =
      insert_digest_section!(digest, %{
        title: "Inbox Highlights",
        summary: summary,
        summary_html: summary_html,
        rank: 1
      })

    [section | sections]
  end

  defp insert_digest_section!(digest, params) do
    params =
      Map.merge(params, %{
        space_id: digest.space_id,
        digest_id: digest.id
      })

    %Schemas.DigestSection{}
    |> Schemas.DigestSection.create_changeset(params)
    |> Repo.insert!()
  end

  defp unread_inbox_count(space_user) do
    space_user
    |> Posts.Query.base_query()
    |> Posts.Query.where_is_unread()
    |> Posts.Query.count()
    |> Repo.one()
  end

  defp assemble_digest({:ok, data}) do
    sections =
      Enum.map(data.sections, fn section ->
        %Section{
          title: section.title,
          summary: section.summary,
          summary_html: section.summary_html,
          link_text: section.link_text,
          link_url: section.link_url,
          posts: []
        }
      end)

    {:ok,
     %Digest{
       id: data.digest.id,
       title: data.digest.title,
       sections: sections,
       start_at: data.digest.start_at,
       end_at: data.digest.end_at
     }}
  end

  defp assemble_digest(_) do
    {:error, "An unexpected error occurred"}
  end

  defp pluralize(count, singular, plural) do
    if count == 1 do
      "#{count} #{singular}"
    else
      "#{count} #{plural}"
    end
  end
end
