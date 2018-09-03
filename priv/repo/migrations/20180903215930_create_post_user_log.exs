defmodule Level.Repo.Migrations.CreatePostUserLog do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE post_user_log_event AS ENUM (
      'MARKED_AS_READ',
      'MARKED_AS_UNREAD',
      'DISMISSED',
      'SUBSCRIBED',
      'UNSUBSCRIBED'
    )
    """

    create table(:post_user_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event, :post_user_log_event, null: false
      add :occurred_at, :naive_datetime, null: false
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id)
    end
  end

  def down do
    drop table(:post_user_log)

    execute """
    DROP TYPE post_user_log_event
    """
  end
end
