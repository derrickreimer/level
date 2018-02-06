defmodule Level.Repo.Migrations.AddSessionSaltToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :session_salt, :text, null: false, default: "salt"
    end
  end
end
