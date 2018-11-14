defmodule Level.Repo.Migrations.AddTimeZoneToDigests do
  use Ecto.Migration

  def change do
    alter table(:digests) do
      add :time_zone, :text, null: false
    end
  end
end
