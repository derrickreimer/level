defmodule Neuron.Repo.Migrations.CreateInvitation do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE user_role AS ENUM ('OWNER','ADMIN','MEMBER')")
    execute("CREATE TYPE invitation_state AS ENUM ('PENDING','ACCEPTED','REVOKED')")

    create table(:invitations) do
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :invitor_id, references(:users, on_delete: :nothing), null: false
      add :acceptor_id, references(:users, on_delete: :nothing)
      add :state, :invitation_state, null: false, default: "PENDING"
      add :role, :user_role, null: false, default: "MEMBER"
      add :email, :string, null: false
      add :token, :uuid, null: false

      timestamps()
    end

    create index(:invitations, [:team_id])
    create index(:invitations, [:invitor_id])
    create unique_index(:invitations, ["lower(email)"], where: "state = 'PENDING'", name: :invitations_unique_pending_email)
    create unique_index(:invitations, [:token])
  end

  def down do
    drop table(:invitations)
    execute("DROP TYPE invitation_state")
    execute("DROP TYPE user_role")
  end
end
