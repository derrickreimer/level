defmodule Neuron.Repo.Migrations.CreateTeamStateEnum do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE team_state AS ENUM ('ACTIVE','DISABLED')")

    alter table(:teams) do
      remove :state
      add :state, :team_state, null: false, default: "ACTIVE"
    end
  end

  def down do
    alter table(:teams) do
      remove :state
      add :state, :integer
    end

    execute("DROP TYPE team_state")
  end
end
