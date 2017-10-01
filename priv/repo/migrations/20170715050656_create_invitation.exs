defmodule Level.Repo.Migrations.CreateInvitation do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE invitation_state AS ENUM ('PENDING','ACCEPTED','REVOKED')")

    create table(:invitations, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :bigint), null: false
      add :invitor_id, references(:users, on_delete: :nothing, type: :bigint), null: false
      add :acceptor_id, references(:users, on_delete: :nothing, type: :bigint)
      add :state, :invitation_state, null: false, default: "PENDING"
      add :role, :user_role, null: false, default: "MEMBER"
      add :email, :text, null: false
      add :token, :uuid, null: false

      timestamps()
    end

    create index(:invitations, [:space_id])
    create index(:invitations, [:invitor_id])
    create unique_index(:invitations, ["lower(email)"], where: "state = 'PENDING'", name: :invitations_unique_pending_email)
    create unique_index(:invitations, [:token])
  end

  def down do
    drop table(:invitations)
    execute("DROP TYPE invitation_state")
  end
end
