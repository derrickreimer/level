defmodule Level.Repo.Migrations.CreateGroupMemberships do
  use Ecto.Migration

  def change do
    create table(:group_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_member_id, references(:space_members, on_delete: :nothing, type: :binary_id),
        null: false

      add :group_id, references(:groups, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:group_memberships, [:id])
    create unique_index(:group_memberships, [:space_member_id, :group_id])
  end
end
