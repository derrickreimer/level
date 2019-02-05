defmodule Level.Repo.Migrations.AddGroupUserAccess do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE group_user_access AS ENUM (
      'PUBLIC',
      'PRIVATE'
    )
    """

    alter table(:group_users) do
      add :access, :group_user_access, null: false, default: "PUBLIC"
    end
  end

  def down do
    alter table(:group_users) do
      remove :access
    end

    execute """
    DROP TYPE group_user_access
    """
  end
end
