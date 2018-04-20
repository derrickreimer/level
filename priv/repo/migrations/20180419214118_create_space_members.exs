defmodule Level.Repo.Migrations.CreateSpaceMembers do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE space_member_role AS ENUM ('OWNER','ADMIN','MEMBER')")
    execute("CREATE TYPE space_member_state AS ENUM ('ACTIVE','DISABLED')")

    create table(:space_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :state, :space_member_state, null: false, default: "ACTIVE"
      add :role, :space_member_role, null: false, default: "MEMBER"

      timestamps()
    end

    create index(:space_members, [:id])
    create unique_index(:space_members, [:space_id, :user_id])
  end

  def down do
    drop table(:space_members)
    execute("DROP TYPE space_member_role")
    execute("DROP TYPE space_member_state")
  end
end
