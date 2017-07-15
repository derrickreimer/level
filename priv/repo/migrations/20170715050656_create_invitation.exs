defmodule Bridge.Repo.Migrations.CreateInvitation do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :invitor_id, references(:users, on_delete: :nothing), null: false
      add :acceptor_id, references(:users, on_delete: :nothing)
      add :state, :integer, null: false
      add :role, :integer, null: false
      add :email, :string, null: false
      add :token, :string, null: false, size: 36

      timestamps()
    end

    create index(:invitations, [:team_id])
    create index(:invitations, [:invitor_id])
    create index(:invitations, [:token])
  end
end
