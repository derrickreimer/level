defmodule Level.Repo.Migrations.AddInboxStateToPostUsers do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE inbox_state AS ENUM (
      'UNREAD',
      'READ',
      'DISMISSED',
      'EXCLUDED'
    )
    """

    alter table(:post_users) do
      add :inbox_state, :inbox_state, null: false, default: "EXCLUDED"
    end
  end

  def down do
    alter table(:post_users) do
      remove :inbox_state
    end

    execute """
    DROP TYPE inbox_state
    """
  end
end
