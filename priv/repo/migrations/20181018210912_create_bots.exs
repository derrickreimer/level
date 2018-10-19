defmodule Level.Repo.Migrations.CreateBots do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE bot_state AS ENUM ('ACTIVE','DISABLED')")
    execute("CREATE TYPE space_bot_state AS ENUM ('ACTIVE','DISABLED')")

    create table(:bots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :state, :bot_state, null: false, default: "ACTIVE"
      add :handle, :citext, null: false
      add :display_name, :text, null: false
      add :avatar, :text

      timestamps()
    end

    create table(:space_bots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :bot_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :state, :space_bot_state, null: false, default: "ACTIVE"
      add :handle, :citext, null: false
      add :display_name, :text, null: false
      add :avatar, :text

      timestamps()
    end

    create unique_index(:bots, ["lower(handle)"])
    create unique_index(:space_bots, [:space_id, "lower(handle)"])
  end

  def down do
    drop table(:bots)
    drop table(:space_bots)
    execute("DROP TYPE bot_state")
    execute("DROP TYPE space_bot_state")
  end
end
