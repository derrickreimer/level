defmodule Level.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE notification_event AS ENUM (
      'POST_CREATED',
      'REPLY_CREATED',
      'POST_CLOSED',
      'POST_REOPENED'
    )
    """

    execute """
    CREATE TYPE notification_state AS ENUM (
      'UNDISMISSED',
      'DISMISSED'
    )
    """

    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :topic, :text, null: false
      add :state, :notification_state, null: false, default: "UNDISMISSED"
      add :event, :notification_event, null: false
      add :data, :map

      timestamps()
    end
  end

  def down do
    drop table(:notifications)
    execute "DROP TYPE notification_event"
    execute "DROP TYPE notification_state"
  end
end
