defmodule Bridge.Repo.Migrations.CreateUserStateEnum do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE user_state AS ENUM ('ACTIVE','DISABLED')")

    alter table(:users) do
      remove :state
      add :state, :user_state, null: false, default: "ACTIVE"
    end
  end
end
