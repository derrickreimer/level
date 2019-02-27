defmodule Level.Repo.Migrations.AddReactionEventsToNotificationEvent do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE notification_event ADD VALUE IF NOT EXISTS 'POST_REACTION_CREATED'"
    execute "ALTER TYPE notification_event ADD VALUE IF NOT EXISTS 'REPLY_REACTION_CREATED'"
  end

  def down do
    execute "DELETE FROM notifications WHERE event IN ('POST_REACTION_CREATED','REPLY_REACTION_CREATED')"
    execute "ALTER TYPE notification_event RENAME TO notification_event_old"

    execute """
    CREATE TYPE notification_event AS ENUM (
      'POST_CREATED',
      'REPLY_CREATED',
      'POST_CLOSED',
      'POST_REOPENED'
    );
    """

    execute "ALTER TABLE notifications ALTER COLUMN event TYPE notification_event USING event::text::notification_event"
    execute "DROP TYPE notification_event_old"
  end
end
