defmodule Level.Repo.Migrations.AddAvatarToSpaces do
  use Ecto.Migration

  def change do
    alter table(:spaces) do
      add :avatar, :text
    end
  end
end
