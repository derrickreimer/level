defmodule Sprinkle.Repo.Migrations.AlterUserRole do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :role
      add :role, :user_role, null: false, default: "MEMBER"
    end
  end

  def down do
    alter table(:users) do
      remove :role
      add :role, :integer
    end
  end
end
