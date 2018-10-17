defmodule Level.Repo.Migrations.CreatePostSearchesView do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW post_searches AS
      SELECT
        posts.space_id AS space_id,
        posts.id AS searchable_id,
        'Post' AS searchable_type,
        posts.id AS post_id,
        posts.body AS document,
        posts.search_vector AS search_vector,
        posts.language::regconfig AS language
      FROM posts

      UNION

      SELECT
        replies.space_id AS space_id,
        replies.id AS searchable_id,
        'Reply' AS searchable_type,
        replies.post_id AS post_id,
        replies.body AS document,
        replies.search_vector AS search_vector,
        replies.language::regconfig AS language
      FROM replies
    """
  end

  def down do
    execute """
    DROP VIEW IF EXISTS post_searches
    """
  end
end
