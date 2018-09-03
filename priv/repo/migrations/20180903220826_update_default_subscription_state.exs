defmodule Level.Repo.Migrations.UpdateDefaultSubscriptionState do
  use Ecto.Migration

  def up do
    alter table(:post_users) do
      modify :subscription_state, :post_subscription_state, null: false, default: "NOT_SUBSCRIBED"
    end
  end

  def down do
    alter table(:post_users) do
      modify :subscription_state, :post_subscription_state, null: false, default: "SUBSCRIBED"
    end
  end
end
