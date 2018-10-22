defmodule Level.Repo.Migrations.CreateGroupInvitations do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE group_invitation_state AS ENUM ('PENDING','ACCEPTED','REVOKED')"

    create table(:group_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :group_id, references(:groups, on_delete: :nothing, type: :binary_id), null: false

      add :invitor_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :invitee_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :state, :group_invitation_state, null: false, default: "PENDING"

      timestamps()
    end

    create unique_index(:group_invitations, [:group_id, :invitee_id],
             where: "state = 'PENDING'",
             name: :group_invitations_unique
           )
  end

  def down do
    drop table(:group_invitations)
    execute "DROP TYPE group_invitation_state"
  end
end
