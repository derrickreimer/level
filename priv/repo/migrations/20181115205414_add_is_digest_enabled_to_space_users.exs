defmodule Level.Repo.Migrations.AddIsDigestEnabledToSpaceUsers do
  use Ecto.Migration

  def change do
    alter table(:space_users) do
      add :is_digest_enabled, :boolean, null: false, default: true
    end
  end
end
