defmodule Level.Repo.Migrations.CreateUserMentions do
  use Ecto.Migration

  def change do
    create table(:user_mentions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :reply_id, references(:replies, on_delete: :nothing, type: :binary_id)

      add :mentioner_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :mentioned_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :dismissed_at, :naive_datetime
      timestamps(inserted_at: :occurred_at)
    end
  end
end
