defmodule Level.Repo.Migrations.CreateSpaceSetupSteps do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE space_setup_state AS ENUM ('CREATE_GROUPS','INVITE_USERS','COMPLETE')")

    create table(:space_setup_transitions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :state, :space_setup_state, null: false
      add :is_skipped, :boolean, null: false

      timestamps()
    end

    create unique_index(:space_setup_transitions, [:space_id, :state])
  end

  def down do
    drop table(:space_setup_transitions)
    execute("DROP TYPE space_setup_state")
  end
end
