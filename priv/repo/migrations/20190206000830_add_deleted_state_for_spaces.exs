defmodule Level.Repo.Migrations.AddDeletedStateForSpaces do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE space_state ADD VALUE IF NOT EXISTS 'DELETED'"
  end

  def down do
    execute "UPDATE spaces SET state = 'DISABLED' WHERE state = 'DELETED'"
    execute "ALTER TYPE space_state RENAME TO space_state_old"
    execute "CREATE TYPE space_state AS ENUM('ACTIVE', 'DISABLED')"

    execute "ALTER TABLE spaces ALTER COLUMN state TYPE space_state USING state::text::space_state"

    execute "DROP TYPE space_state_old"
  end
end
