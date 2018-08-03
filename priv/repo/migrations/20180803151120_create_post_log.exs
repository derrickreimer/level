defmodule Level.Repo.Migrations.CreatePostLog do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE post_log_event AS ENUM (
      'POST_CREATED',
      'POST_EDITED',
      'POST_CLOSED',
      'POST_REOPENED',
      'REPLY_CREATED',
      'REPLY_EDITED',
      'REPLY_DELETED'
    )
    """

    create table(:post_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event, :post_log_event, null: false
      add :occurred_at, :naive_datetime, null: false
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :group_id, references(:groups, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :actor_id, references(:space_users, on_delete: :nothing, type: :binary_id)
      add :reply_id, references(:replies, on_delete: :nothing, type: :binary_id)
    end
  end

  def down do
    drop table(:post_log)
    execute("DROP TYPE post_log_event")
  end
end
