defmodule Level.Repo.Migrations.AddIsDemoFlagToSpaces do
  use Ecto.Migration

  def change do
    alter table(:spaces) do
      add :is_demo, :boolean, null: false, default: false
    end
  end
end
