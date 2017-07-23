defmodule Bridge.Repo.Migrations.AlterUserRole do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :role
      add :role, :user_role, null: false, default: "MEMBER"
    end
  end
end
