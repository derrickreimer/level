defmodule Level.Repo.Migrations.CreateOpenInvitations do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE open_invitation_state AS ENUM ('ACTIVE','REVOKED')")

    create table(:open_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :state, :open_invitation_state, null: false, default: "ACTIVE"
      add :token, :text

      timestamps()
    end

    create unique_index(
             :open_invitations,
             [:space_id],
             where: "state = 'ACTIVE'",
             name: :open_invitations_unique_active
           )

    create unique_index(:open_invitations, [:token])
  end

  def down do
    drop table(:open_invitations)
    execute("DROP TYPE open_invitation_state")
  end
end
