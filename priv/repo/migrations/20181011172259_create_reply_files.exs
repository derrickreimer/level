defmodule Level.Repo.Migrations.CreateReplyFiles do
  use Ecto.Migration

  def change do
    create table(:reply_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :reply_id, references(:replies, on_delete: :nothing, type: :binary_id), null: false
      add :file_id, references(:files, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(updated_at: false)
    end

    create index(:reply_files, [:reply_id])
  end
end
