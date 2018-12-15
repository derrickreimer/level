defmodule Level.Repo.Migrations.AddReactionEventsToPostLogEvent do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE post_log_event ADD VALUE IF NOT EXISTS 'POST_REACTION_CREATED'"
    execute "ALTER TYPE post_log_event ADD VALUE IF NOT EXISTS 'REPLY_REACTION_CREATED'"
  end

  def down do
    execute "DELETE FROM post_log WHERE event IN ('POST_REACTION_CREATED','REPLY_REACTION_CREATED')"
    execute "ALTER TYPE post_log_event RENAME TO post_log_event_old"

    execute """
    CREATE TYPE post_log_event AS ENUM (
        'POST_CREATED',
        'POST_EDITED',
        'POST_CLOSED',
        'POST_REOPENED',
        'REPLY_CREATED',
        'REPLY_EDITED',
        'REPLY_DELETED'
    );
    """

    execute "ALTER TABLE post_log ALTER COLUMN event TYPE post_log_event USING event::text::post_log_event"
    execute "DROP TYPE post_log_event_old"
  end
end
