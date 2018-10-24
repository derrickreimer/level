defmodule Level.Repo.Migrations.AddStateToGroupUsers do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE group_user_state AS ENUM ('NOT_SUBSCRIBED','SUBSCRIBED')"
    execute "CREATE TYPE group_user_role AS ENUM ('MEMBER','OWNER')"

    alter table(:group_users) do
      add :state, :group_user_state, null: false, default: "NOT_SUBSCRIBED"
      add :role, :group_user_role, null: false, default: "MEMBER"
    end
  end

  def down do
    alter table(:group_users) do
      remove :state
      remove :role
    end

    execute "DROP TYPE group_user_state"
    execute "DROP TYPE group_user_role"
  end
end
