defmodule Level.Repo.Migrations.AddSubscriberPolicyToRooms do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE room_subscriber_policy AS ENUM ('MANDATORY','PUBLIC','INVITE_ONLY')")

    alter table(:rooms) do
      remove :is_private
      add :subscriber_policy, :room_subscriber_policy, default: "PUBLIC"
    end
  end

  def down do
    alter table(:rooms) do
      add :is_private, :boolean, null: false, default: false
      remove :subscriber_policy
    end

    execute("DROP TYPE room_subscriber_policy")
  end
end
