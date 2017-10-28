defmodule Level.Repo.Migrations.CreateRoomMessage do
  use Ecto.Migration

  def change do
    create table(:room_messages, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :bigint), null: false
      add :user_id, references(:users, on_delete: :nothing, type: :bigint), null: false
      add :room_id, references(:rooms, on_delete: :nothing, type: :bigint), null: false
      add :body, :text, null: false

      timestamps()
    end

    create index(:room_messages, [:id])
    create index(:room_messages, [:room_id])
  end
end
