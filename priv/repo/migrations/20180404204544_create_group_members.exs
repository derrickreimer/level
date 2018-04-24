defmodule Level.Repo.Migrations.CreateGroupMembers do
  use Ecto.Migration

  def change do
    create table(:group_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_member_id, references(:space_members, on_delete: :nothing, type: :binary_id),
        null: false

      add :group_id, references(:groups, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:group_members, [:id])
    create unique_index(:group_members, [:space_member_id, :group_id])
  end
end
