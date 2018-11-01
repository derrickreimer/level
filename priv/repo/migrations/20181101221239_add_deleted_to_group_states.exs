defmodule Level.Repo.Migrations.AddDeletedToGroupStates do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE group_state ADD VALUE IF NOT EXISTS 'DELETED'"
  end

  def down do
    execute "UPDATE groups SET state = 'CLOSED' WHERE state = 'DELETED'"
    execute "ALTER TYPE group_state RENAME TO group_state_old"
    execute "CREATE TYPE group_state AS ENUM('OPEN', 'CLOSED')"

    execute "ALTER TABLE groups ALTER COLUMN state TYPE group_state USING state::text::group_state"

    execute "DROP TYPE group_state_old"
  end
end
