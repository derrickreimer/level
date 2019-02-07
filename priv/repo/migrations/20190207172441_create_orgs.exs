defmodule Level.Repo.Migrations.CreateOrgs do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE subscription_state AS ENUM (
      'NONE',
      'TRIALING',
      'ACTIVE',
      'PAST_DUE',
      'CANCELED',
      'UNPAID'
    )
    """

    create table(:orgs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :text, null: false
      add :stripe_customer_id, :text
      add :stripe_subscription_id, :text
      add :subscription_state, :subscription_state, null: false, default: "NONE"
      add :seat_quantity, :integer, null: false

      timestamps()
    end
  end

  def down do
    drop table(:orgs)
    execute "DROP TYPE subscription_state"
  end
end
