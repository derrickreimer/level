defmodule Bridge.Repo.Migrations.CreateTeam do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :state, :integer, null: false
      add :slug, :string, null: false, size: 63 # a subdomain can only be 63 chars

      timestamps()
    end

    create unique_index(:teams, :slug)
  end
end
