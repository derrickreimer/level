defmodule Bridge.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :pod_id, references(:pods, on_delete: :nothing), null: false
      add :state, :integer, null: false
      add :role, :integer, null: false
      add :email, :string, null: false
      add :username, :string, null: false, size: 20
      add :first_name, :string
      add :last_name, :string
      add :time_zone, :string, null: false
      add :password_hash, :string, null: false

      timestamps()
    end

    create index(:users, [:pod_id])
    create unique_index(:users, [:pod_id, :email])
    create unique_index(:users, [:pod_id, :username])
  end
end
