defmodule Level.Repo.Migrations.AddNewValuesToSubscriptionStates do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "ALTER TYPE subscription_state ADD VALUE IF NOT EXISTS 'INCOMPLETE'"
    execute "ALTER TYPE subscription_state ADD VALUE IF NOT EXISTS 'INCOMPLETE_EXPIRED'"
  end

  def down do
    execute "UPDATE orgs SET subscription_state = 'NONE' WHERE subscription_state IN ('INCOMPLETE','INCOMPLETE_EXPIRED')"
    execute "ALTER TYPE subscription_state RENAME TO subscription_state_old"

    execute """
    CREATE TYPE subscription_state AS ENUM (
      'NONE',
      'TRIALING',
      'ACTIVE',
      'PAST_DUE',
      'CANCELED',
      'UNPAID'
    );
    """

    execute "ALTER TABLE orgs ALTER COLUMN subscription_state TYPE subscription_state USING subscription_state::text::subscription_state"
    execute "DROP TYPE subscription_state_old"
  end
end
