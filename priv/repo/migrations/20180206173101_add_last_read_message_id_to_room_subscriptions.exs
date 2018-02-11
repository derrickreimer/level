defmodule Level.Repo.Migrations.AddLastReadMessageIdToRoomSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:room_subscriptions) do
      add :last_read_message_id, references(:room_messages, on_delete: :nothing, type: :bigint)
      add :last_read_message_at, :utc_datetime
    end
  end
end
