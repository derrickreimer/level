defmodule Level.Repo.Migrations.AddNameFieldsToSpaceUsers do
  use Ecto.Migration

  import Ecto.Query

  def up do
    alter table(:space_users) do
      add :first_name, :text
      add :last_name, :text
    end

    flush()

    query =
      from su in "space_users",
        join: u in "users",
        on: su.user_id == u.id,
        update: [set: [first_name: u.first_name, last_name: u.last_name]]

    Level.Repo.update_all(query, [])

    alter table(:space_users) do
      modify :first_name, :text, null: false
      modify :last_name, :text, null: false
    end
  end

  def down do
    alter table(:space_users) do
      remove :first_name
      remove :last_name
    end
  end
end
