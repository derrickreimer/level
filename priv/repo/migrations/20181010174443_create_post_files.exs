defmodule Level.Repo.Migrations.CreatePostFiles do
  use Ecto.Migration

  def change do
    create table(:post_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :file_id, references(:files, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(updated_at: false)
    end

    create index(:post_files, [:post_id])
  end
end
