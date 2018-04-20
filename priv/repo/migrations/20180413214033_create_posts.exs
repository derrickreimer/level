defmodule Level.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE post_state AS ENUM ('OPEN','CLOSED')")

    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false

      add :space_member_id, references(:space_members, on_delete: :nothing, type: :binary_id),
        null: false

      add :state, :post_state, null: false, default: "OPEN"
      add :body, :text, null: false

      timestamps()
    end

    create index(:posts, [:id])
  end

  def down do
    drop table(:posts)
    execute("DROP TYPE post_state")
  end
end
