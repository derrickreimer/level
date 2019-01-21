defmodule Level.Repo.Migrations.AddSpaceBotToPostLog do
  use Ecto.Migration

  def change do
    alter table(:post_log) do
      modify :actor_id, :binary_id, null: true
      add :space_bot_id, references(:space_bots, on_delete: :nothing, type: :binary_id)
    end

    rename(table("post_log"), :actor_id, to: :space_user_id)
  end
end
