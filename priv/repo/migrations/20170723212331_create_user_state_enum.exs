defmodule Level.Repo.Migrations.CreateUserStateEnum do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE user_state AS ENUM ('ACTIVE','DISABLED')")

    alter table(:users) do
      remove :state
      add :state, :user_state, null: false, default: "ACTIVE"
    end
  end

  def down do
    alter table(:users) do
      remove :state
      add :state, :integer
    end

    execute("DROP TYPE user_state")
  end
end
