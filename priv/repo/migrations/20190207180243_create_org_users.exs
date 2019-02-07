defmodule Level.Repo.Migrations.CreateOrgUsers do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE org_user_role AS ENUM (
      'OWNER',
      'ADMIN',
      'MEMBER'
    )
    """

    execute """
    CREATE TYPE org_user_state AS ENUM (
      'ACTIVE',
      'DISABLED'
    )
    """

    create table(:org_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :org_id, references(:orgs, on_delete: :nothing, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :role, :org_user_role, null: false
      add :state, :org_user_state, null: false, default: "ACTIVE"

      timestamps()
    end
  end

  def down do
    drop table(:org_users)
    execute "DROP TYPE org_user_role"
    execute "DROP TYPE org_user_state"
  end
end
