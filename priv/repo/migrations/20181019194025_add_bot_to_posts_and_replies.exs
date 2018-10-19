defmodule Level.Repo.Migrations.AddBotToPostsAndReplies do
  use Ecto.Migration

  def up do
    alter table(:posts) do
      modify :space_user_id, :binary_id, null: true
      add :space_bot_id, references(:space_bots, on_delete: :nothing, type: :binary_id)
    end

    alter table(:replies) do
      modify :space_user_id, :binary_id, null: true
      add :space_bot_id, references(:space_bots, on_delete: :nothing, type: :binary_id)
    end
  end

  def down do
    alter table(:posts) do
      modify :space_user_id, :binary_id, null: false
      remove :space_bot_id
    end

    alter table(:replies) do
      modify :space_user_id, :binary_id, null: false
      remove :space_bot_id
    end
  end
end
