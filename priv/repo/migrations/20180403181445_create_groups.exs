defmodule Level.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE group_state AS ENUM ('OPEN','CLOSED')")

    create table(:groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :state, :group_state, default: "OPEN", null: false
      add :name, :text, null: false
      add :description, :text
      add :is_private, :boolean, default: false, null: false
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :creator_id, references(:users, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:groups, [:id])
    create index(:groups, [:space_id])
    create unique_index(:groups, ["lower(name)"], where: "state = 'OPEN'", name: :groups_unique_names_when_open)
  end

  def down do
    drop table(:groups)
    execute("DROP TYPE group_state")
  end
end
