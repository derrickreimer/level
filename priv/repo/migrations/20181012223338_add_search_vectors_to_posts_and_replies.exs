defmodule Level.Repo.Migrations.AddSearchVectorsToPostsAndReplies do
  use Ecto.Migration

  def up do
    alter table(:posts) do
      add :search_vector, :tsvector
    end

    alter table(:replies) do
      add :search_vector, :tsvector
    end

    execute """
    CREATE FUNCTION posts_search_vector_trigger() RETURNS trigger AS $$
    begin
      new.search_vector :=
         to_tsvector(new.language::regconfig, new.body);
      return new;
    end
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER update_search_vector BEFORE INSERT OR UPDATE
    ON posts FOR EACH ROW EXECUTE PROCEDURE
    posts_search_vector_trigger();
    """

    execute """
    CREATE FUNCTION replies_search_vector_trigger() RETURNS trigger AS $$
    begin
      new.search_vector :=
         to_tsvector(new.language::regconfig, new.body);
      return new;
    end
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER update_search_vector BEFORE INSERT OR UPDATE
    ON replies FOR EACH ROW EXECUTE PROCEDURE
    replies_search_vector_trigger();
    """

    execute """
    CREATE INDEX posts_search_vector_index ON posts USING GIN (search_vector);
    """

    execute """
    CREATE INDEX replies_search_vector_index ON replies USING GIN (search_vector);
    """
  end

  def down do
    alter table(:posts) do
      remove :search_vector
    end

    alter table(:replies) do
      remove :search_vector
    end

    execute """
    DROP TRIGGER update_search_vector ON posts;
    """

    execute """
    DROP FUNCTION posts_search_vector_trigger;
    """

    execute """
    DROP TRIGGER update_search_vector ON replies;
    """

    execute """
    DROP FUNCTION replies_search_vector_trigger;
    """
  end
end
