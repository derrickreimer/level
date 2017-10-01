defmodule Level.Repo.Migrations.CreateSpace do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE space_state AS ENUM ('ACTIVE','DISABLED')")

    create table(:spaces, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :state, :space_state, null: false, default: "ACTIVE"
      add :name, :text, null: false
      add :slug, :text, null: false

      timestamps()
    end

    create unique_index(:spaces, :slug)
  end

  def down do
    drop table(:spaces)
    execute("DROP TYPE space_state")
  end
end
