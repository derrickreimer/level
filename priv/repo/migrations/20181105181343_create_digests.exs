defmodule Level.Repo.Migrations.CreateDigests do
  use Ecto.Migration

  def change do
    create table(:digests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :title, :text, null: false
      add :start_at, :naive_datetime, null: false
      add :end_at, :naive_datetime, null: false

      timestamps()
    end
  end
end
