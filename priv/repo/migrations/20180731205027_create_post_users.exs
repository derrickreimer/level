defmodule Level.Repo.Migrations.CreatePostUsers do
  use Ecto.Migration

  def up do
    execute(
      "CREATE TYPE post_subscription_state AS ENUM ('NOT_SUBSCRIBED','SUBSCRIBED','UNSUBSCRIBED')"
    )

    create table(:post_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false

      add :space_user_id, references(:space_users, on_delete: :nothing, type: :binary_id),
        null: false

      add :subscription_state, :post_subscription_state, null: false, default: "SUBSCRIBED"
      timestamps()
    end

    create unique_index(:post_users, [:post_id, :space_user_id])
  end

  def down do
    drop table(:post_users)
    execute("DROP TYPE post_subscription_state")
  end
end
