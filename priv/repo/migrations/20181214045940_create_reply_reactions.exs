defmodule Level.Repo.Migrations.CreateReplyReactions do
  use Ecto.Migration

  def change do
    create table(:reply_reactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :reply_id, references(:replies, on_delete: :nothing, type: :binary_id), null: false

      add :value, :text, null: false

      timestamps()
    end

    create unique_index(:reply_reactions, [:space_user_id, :reply_id, :value])
  end
end
