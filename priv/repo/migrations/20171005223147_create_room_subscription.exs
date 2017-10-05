defmodule Level.Repo.Migrations.CreateRoomSubscription do
  use Ecto.Migration

  def change do
    create table(:room_subscriptions, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :bigint), null: false
      add :user_id, references(:users, on_delete: :nothing, type: :bigint), null: false
      add :room_id, references(:rooms, on_delete: :nothing, type: :bigint), null: false

      timestamps()
    end

    create index(:room_subscriptions, [:id])
    create index(:room_subscriptions, [:user_id])
    create index(:room_subscriptions, [:room_id])
  end
end
