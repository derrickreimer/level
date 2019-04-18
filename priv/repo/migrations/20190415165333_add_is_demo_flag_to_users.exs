defmodule Level.Repo.Migrations.AddIsDemoFlagToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_demo, :boolean, null: false, default: false
      add :has_password, :boolean, null: false, default: true
      add :has_chosen_handle, :boolean, null: false, default: true
    end

    alter table(:space_users) do
      add :is_demo, :boolean, null: false, default: false
    end
  end
end
