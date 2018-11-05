defmodule Level.Repo.Migrations.CreateDigestPosts do
  use Ecto.Migration

  def change do
    create table(:digest_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :digest_id, references(:digests, on_delete: :nothing, type: :binary_id), null: false

      add :digest_section_id, references(:digest_sections, on_delete: :nothing, type: :binary_id),
        null: false

      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :rank, :integer, null: false

      timestamps()
    end
  end
end
