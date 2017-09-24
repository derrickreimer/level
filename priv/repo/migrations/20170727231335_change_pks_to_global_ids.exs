defmodule Level.Repo.Migrations.ChangePksToGlobalIds do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      modify :id, :bigint, null: false, default: fragment("next_global_id()")
    end

    alter table(:users) do
      modify :id, :bigint, null: false, default: fragment("next_global_id()")
      modify :team_id, :bigint, null: false
    end

    alter table(:invitations) do
      modify :id, :bigint, null: false, default: fragment("next_global_id()")
      modify :team_id, :bigint, null: false
      modify :invitor_id, :bigint, null: false
      modify :acceptor_id, :bigint
    end

    execute "DROP SEQUENCE teams_id_seq"
    execute "DROP SEQUENCE users_id_seq"
    execute "DROP SEQUENCE invitations_id_seq"
  end
end
