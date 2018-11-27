defmodule Level.Repo.Migrations.CreateTutorials do
  use Ecto.Migration

  def change do
    create table(:tutorials, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :key, :string, null: false
      add :current_step, :integer, null: false, default: 1
      add :is_complete, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:tutorials, [:space_user_id, :key])
  end
end
