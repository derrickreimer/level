defmodule Level.Repo.Migrations.AddUniqueIndexOnRoomSubscriptions do
  use Ecto.Migration

  def change do
    create unique_index(:room_subscriptions, [:user_id, :room_id], name: :room_subscriptions_unique)
  end
end
