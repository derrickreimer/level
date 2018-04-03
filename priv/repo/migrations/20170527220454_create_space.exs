defmodule Level.Repo.Migrations.CreateSpace do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION citext")
    execute("CREATE TYPE space_state AS ENUM ('ACTIVE','DISABLED')")

    create table(:spaces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :state, :space_state, null: false, default: "ACTIVE"
      add :name, :text, null: false
      add :slug, :citext, null: false

      timestamps()
    end

    create index(:spaces, [:id])
    create unique_index(:spaces, ["lower(slug)"])
  end

  def down do
    drop table(:spaces)
    execute("DROP TYPE space_state")
  end
end
