defmodule Level.Repo.Migrations.AddAvatarToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar, :text
    end

    alter table(:space_users) do
      add :avatar, :text
    end
  end
end
