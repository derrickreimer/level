defmodule Level.Digests.Compiler do
  @moduledoc false

  alias Level.Digests.Digest
  alias Level.Digests.Post
  alias Level.Digests.Section
  alias Level.Schemas
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceUser

  @spec compile_digest(SpaceUser.t(), Space.t(), Schemas.Digest.t()) :: Digest.t()
  def compile_digest(space_user, space, digest) do
    compile_digest(
      space_user,
      space,
      digest,
      compile_sections(space_user, digest.digest_sections)
    )
  end

  @spec compile_digest(SpaceUser.t(), Space.t(), Schemas.Digest.t(), [Section.t()]) :: Digest.t()
  def compile_digest(space_user, space, digest, compiled_sections) do
    %Digest{
      id: digest.id,
      space_user: space_user,
      space: space,
      title: digest.title,
      subject: digest.subject,
      to_email: digest.to_email,
      sections: compiled_sections,
      start_at: digest.start_at,
      end_at: digest.end_at,
      time_zone: digest.time_zone
    }
  end

  @spec compile_sections(SpaceUser.t(), [Schemas.DigestSection.t()]) :: [Section.t()]
  def compile_sections(space_user, sections) do
    sections
    |> Enum.sort(&(&1.rank <= &2.rank))
    |> Enum.map(fn section -> compile_section(space_user, section) end)
  end

  @spec compile_section(SpaceUser.t(), Schemas.DigestSection.t()) :: Section.t()
  def compile_section(space_user, section) do
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
      posts: compile_posts(space_user, posts)
    }
  end

  @spec compile_section(SpaceUser.t(), Schemas.DigestSection.t(), [Post.t()]) :: Section.t()
  def compile_section(_space_user, section, compiled_posts) do
    %Section{
      title: section.title,
      summary: section.summary,
      summary_html: section.summary_html,
      link_text: section.link_text,
      link_url: section.link_url,
      posts: compiled_posts
    }
  end

  @spec compile_posts(SpaceUser.t(), [Schemas.Post.t()]) :: [Post.t()]
  def compile_posts(space_user, posts) do
    Enum.map(posts, fn post -> compile_post(space_user, post) end)
  end

  @spec compile_post(SpaceUser.t(), Schemas.Post.t()) :: Post.t()
  def compile_post(space_user, post) do
    Post.build(space_user, post)
  end
end
