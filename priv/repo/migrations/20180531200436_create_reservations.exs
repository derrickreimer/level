defmodule Level.Repo.Migrations.CreateReservations do
  use Ecto.Migration

  def change do
    create table(:reservations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :handle, :citext, null: false
      timestamps()
    end

    create unique_index(:reservations, ["lower(email)"])
    create unique_index(:reservations, ["lower(handle)"])
  end
end
