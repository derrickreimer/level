defmodule Level.Repo.Migrations.AddOrgIdToSpaces do
  use Ecto.Migration

  def change do
    alter table(:spaces) do
      add :org_id, references(:orgs, on_delete: :nothing, type: :binary_id)
    end
  end
end
