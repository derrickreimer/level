defmodule Level.Repo.Migrations.CreateThread do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE thread_state AS ENUM ('SENT','DELETED')")

    create table(:threads, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :team_id, references(:teams, on_delete: :nothing, type: :bigint), null: false
      add :creator_id, references(:users, on_delete: :nothing, type: :bigint), null: false
      add :state, :thread_state, default: "SENT", null: false
      add :subject, :string, null: false

      timestamps()
    end

    create index(:threads, [:id])
    create index(:threads, [:team_id])
  end

  def down do
    drop table(:threads)
    execute("DROP TYPE thread_state")
  end
end
