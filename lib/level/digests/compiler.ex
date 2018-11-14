defmodule Level.Digests.Compiler do
  @moduledoc false

  alias Level.Digests.Digest
  alias Level.Digests.Post
  alias Level.Digests.Section
  alias Level.Schemas
  alias Level.Schemas.Space

  @spec compile_digest(Space.t(), Schemas.Digest.t()) :: Digest.t()
  def compile_digest(space, digest) do
    compile_digest(space, digest, compile_sections(digest.digest_sections))
  end

  @spec compile_digest(Space.t(), Schemas.Digest.t(), [Section.t()]) :: Digest.t()
  def compile_digest(space, digest, compiled_sections) do
    %Digest{
      id: digest.id,
      space_id: digest.space_id,
      space_name: space.name,
      title: digest.title,
      subject: digest.subject,
      to_email: digest.to_email,
      sections: compiled_sections,
      start_at: digest.start_at,
      end_at: digest.end_at,
      time_zone: digest.time_zone
    }
  end

  @spec compile_sections([Schemas.DigestSection.t()]) :: [Section.t()]
  def compile_sections(sections) do
    sections
    |> Enum.sort(&(&1.rank <= &2.rank))
    |> Enum.map(&compile_section/1)
  end

  @spec compile_section(Schemas.DigestSection.t()) :: Section.t()
  def compile_section(section) do
    posts =
      section.digest_posts
      |> Enum.sort(&(&1.rank <= &2.rank))
      |> Enum.map(& &1.post)

    %Section{
      title: section.title,
      summary: section.summary,
      summary_html: section.summary_html,
      link_text: section.link_text,
      link_url: section.link_url,
      posts: compile_posts(posts)
    }
  end

  @spec compile_section(Schemas.DigestSection.t(), [Post.t()]) :: Section.t()
  def compile_section(section, compiled_posts) do
    %Section{
      title: section.title,
      summary: section.summary,
      summary_html: section.summary_html,
      link_text: section.link_text,
      link_url: section.link_url,
      posts: compiled_posts
    }
  end

  @spec compile_posts([Schemas.Post.t()]) :: [Post.t()]
  def compile_posts(posts) do
    Enum.map(posts, &compile_post/1)
  end

  @spec compile_post(Schemas.Post.t()) :: Post.t()
  def compile_post(post) do
    Post.build(post)
  end
end
