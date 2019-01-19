defmodule Level.Repo.Migrations.AddDeletedToReplyState do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    alter table(:replies) do
      add :is_deleted, :boolean, null: false, default: false
    end
  end
end
