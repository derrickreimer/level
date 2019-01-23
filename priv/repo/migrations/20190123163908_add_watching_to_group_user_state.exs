defmodule Level.Repo.Migrations.AddWatchingToGroupUserState do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE group_user_state ADD VALUE IF NOT EXISTS 'WATCHING'"
  end

  def down do
    execute "UPDATE posts SET state = 'SUBSCRIBED' WHERE state = 'WATCHING'"
    execute "ALTER TYPE group_user_state RENAME TO group_user_state_old"
    execute "CREATE TYPE group_user_state AS ENUM('NOT_SUBSCRIBED', 'SUBSCRIBED')"

    execute "ALTER TABLE group_users ALTER COLUMN state TYPE group_user_state USING state::text::group_user_state"

    execute "DROP TYPE group_user_state_old"
  end
end
