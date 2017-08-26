defmodule Bridge.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE message_state AS ENUM ('DRAFT','SENT','DELETED')")

    create table(:messages, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :team_id, references(:teams, on_delete: :nothing, type: :bigint), null: false
      add :user_id, references(:users, on_delete: :nothing, type: :bigint), null: false
      add :thread_id, references(:threads, on_delete: :nothing, type: :bigint), null: false
      add :state, :message_state, default: "DRAFT", null: false
      add :body, :text, null: false
      add :is_truncated, :boolean, null: false, default: false

      timestamps()
    end

    create index(:messages, [:id])
    create index(:messages, [:thread_id])
  end

  def down do
    drop table(:messages)
    execute("DROP TYPE message_state")
  end
end
