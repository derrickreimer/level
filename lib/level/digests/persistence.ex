defmodule Level.Digests.Persistence do
  @moduledoc false

  alias Level.Digests
  alias Level.Repo
  alias Level.Schemas.Digest
  alias Level.Schemas.DigestPost
  alias Level.Schemas.DigestSection

  def insert_section!(%Digest{} = digest, params) do
    params =
      Map.merge(params, %{
        space_id: digest.space_id,
        digest_id: digest.id
      })

    %DigestSection{}
    |> DigestSection.create_changeset(params)
    |> Repo.insert!()
  end

  def insert_posts!(%Digest{} = digest, %DigestSection{} = section, posts) do
    posts
    |> Enum.with_index()
    |> Enum.map(fn {post, rank} -> insert_post!(digest, section, post, rank) end)
  end

  def insert_post!(%Digest{} = digest, %DigestSection{} = section, %Digests.Post{} = post, rank) do
    params = %{
      space_id: digest.space_id,
      digest_id: digest.id,
      digest_section_id: section.id,
      post_id: post.id,
      rank: rank
    }

    %DigestPost{}
    |> DigestPost.create_changeset(params)
    |> Repo.insert!()
  end
end
