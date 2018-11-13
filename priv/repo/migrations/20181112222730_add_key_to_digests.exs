defmodule Level.Repo.Migrations.AddKeyToDigests do
  use Ecto.Migration

  def change do
    alter table(:digests) do
      add :key, :text, null: false
    end

    create unique_index(:digests, [:space_user_id, :key])
  end
end
