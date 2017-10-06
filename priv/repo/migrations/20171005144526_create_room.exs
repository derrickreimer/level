defmodule Level.Repo.Migrations.CreateRoom do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE room_state AS ENUM ('ACTIVE','DELETED')")

    create table(:rooms, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :bigint), null: false
      add :creator_id, references(:users, on_delete: :nothing, type: :bigint), null: false
      add :state, :room_state, null: false, default: "ACTIVE"
      add :name, :text, null: false
      add :description, :text, null: false, default: ""
      add :is_private, :boolean, null: false, default: false

      timestamps()
    end

    create index(:rooms, [:id])
    create index(:rooms, [:space_id])
    create unique_index(:rooms, [:space_id, "lower(name)"], where: "NOT state = 'DELETED'", name: :rooms_unique_ci_name)
  end

  def down do
    drop table(:rooms)
    execute("DROP TYPE room_state")
  end
end
