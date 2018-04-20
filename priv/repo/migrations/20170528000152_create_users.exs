defmodule Level.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE user_state AS ENUM ('ACTIVE','DISABLED')")

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :state, :user_state, null: false, default: "ACTIVE"
      add :email, :citext, null: false
      add :first_name, :text, null: false
      add :last_name, :text, null: false
      add :time_zone, :text, null: false
      add :password_hash, :text
      add :session_salt, :text, null: false, default: "salt"

      timestamps()
    end

    create index(:users, [:id])
    create unique_index(:users, ["lower(email)"])
  end

  def down do
    drop table(:users)
    execute("DROP TYPE user_state")
  end
end
