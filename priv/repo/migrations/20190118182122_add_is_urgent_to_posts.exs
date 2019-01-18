defmodule Level.Repo.Migrations.AddIsUrgentToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :is_urgent, :boolean, null: false, default: false
    end
  end
end
