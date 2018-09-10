defmodule Level.Repo.Migrations.CreatePushSubscriptions do
  use Ecto.Migration

  def change do
    create table(:push_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :digest, :text, null: false
      add :data, :text, null: false
      timestamps()
    end

    create unique_index(:push_subscriptions, [:user_id, :digest])
  end
end
