defmodule Level.Repo.Migrations.AddHandleToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :handle, :citext
    end

    alter table(:space_users) do
      add :handle, :citext
    end

    flush()

    execute """
    UPDATE users u SET (id, handle) = (
      SELECT id, handle FROM (
        SELECT id, 'user' || ROW_NUMBER() OVER () as handle
        FROM users u2
      ) u3
      WHERE u.id = u3.id
    )
    """

    execute """
    UPDATE space_users su SET (user_id, handle) = (
      SELECT id, handle FROM (
        SELECT id, 'user' || ROW_NUMBER() OVER () as handle
        FROM users u2
      ) u3
      WHERE su.user_id = u3.id
    )
    """

    flush()

    alter table(:users) do
      modify :handle, :citext, null: false
    end

    alter table(:space_users) do
      modify :handle, :citext, null: false
    end

    create unique_index(:users, ["lower(handle)"])
    create unique_index(:space_users, [:space_id, "lower(handle)"])
  end

  def down do
    alter table(:users) do
      remove :handle
    end

    alter table(:space_users) do
      remove :handle
    end
  end
end
