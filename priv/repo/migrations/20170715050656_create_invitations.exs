defmodule Level.Repo.Migrations.CreateInvitations do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE invitation_state AS ENUM ('PENDING','ACCEPTED','REVOKED')")

    create table(:invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :invitor_id, references(:space_members, on_delete: :nothing, type: :binary_id),
        null: false

      add :acceptor_id, references(:space_members, on_delete: :nothing, type: :binary_id)
      add :role, :space_member_role, null: false, default: "MEMBER"
      add :state, :invitation_state, null: false, default: "PENDING"
      add :email, :citext, null: false
      add :token, :uuid, null: false

      timestamps()
    end

    create index(:invitations, [:id])
    create index(:invitations, [:space_id])
    create unique_index(:invitations, [:token])

    create(
      unique_index(
        :invitations,
        [:space_id, "lower(email)"],
        where: "state = 'PENDING'",
        name: :invitations_unique_pending_email
      )
    )
  end

  def down do
    drop table(:invitations)
    execute("DROP TYPE invitation_state")
  end
end
