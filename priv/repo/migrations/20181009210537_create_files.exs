defmodule Level.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :filename, :text, null: false
      add :content_type, :text
      add :size, :integer, null: false

      timestamps()
    end
  end
end
