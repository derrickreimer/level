defmodule Level.Repo.Migrations.CreatePostUploads do
  use Ecto.Migration

  def change do
    create table(:post_uploads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :upload_id, references(:uploads, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(updated_at: false)
    end

    create index(:post_uploads, [:post_id])
  end
end
