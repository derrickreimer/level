defmodule Level.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE user_role AS ENUM ('OWNER','ADMIN','MEMBER')")
    execute("CREATE TYPE user_state AS ENUM ('ACTIVE','DISABLED')")

    create table(:users, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :bigint), null: false
      add :state, :user_state, null: false, default: "ACTIVE"
      add :role, :user_role, null: false, default: "MEMBER"
      add :email, :text, null: false
      add :username, :text, null: false
      add :first_name, :text
      add :last_name, :text
      add :time_zone, :text, null: false
      add :password_hash, :text, null: false

      timestamps()
    end

    create index(:users, [:space_id])
    create unique_index(:users, [:space_id, :email])
    create unique_index(:users, [:space_id, :username])
  end

  def down do
    drop table(:users)
    execute("DROP TYPE user_role")
    execute("DROP TYPE user_state")
  end
end
