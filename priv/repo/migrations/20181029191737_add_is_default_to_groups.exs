defmodule Level.Repo.Migrations.AddIsDefaultToGroups do
  use Ecto.Migration

  def change do
    alter table(:groups) do
      add :is_default, :boolean, null: false, default: false
    end
  end
end
