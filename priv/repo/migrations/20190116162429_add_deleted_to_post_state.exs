defmodule Level.Repo.Migrations.AddDeletedToPostState do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE post_state ADD VALUE IF NOT EXISTS 'DELETED'"
  end

  def down do
    execute "UPDATE posts SET state = 'CLOSED' WHERE state = 'DELETED'"
    execute "ALTER TYPE post_state RENAME TO post_state_old"
    execute "CREATE TYPE post_state AS ENUM('OPEN', 'CLOSED')"

    execute "ALTER TABLE posts ALTER COLUMN state TYPE post_state USING state::text::post_state"

    execute "DROP TYPE post_state_old"
  end
end
