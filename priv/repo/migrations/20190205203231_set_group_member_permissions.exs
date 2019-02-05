defmodule Level.Repo.Migrations.SetGroupMemberPermissions do
  use Ecto.Migration

  def up do
    execute """
    UPDATE group_users
    SET access = 'PRIVATE'
    WHERE state IN ('SUBSCRIBED', 'WATCHING') OR role = 'OWNER'
    """
  end

  def down do
  end
end
