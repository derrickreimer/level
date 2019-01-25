defmodule Level.Repo.Migrations.AddPostbotKeyToSpaces do
  use Ecto.Migration

  def change do
    alter table(:spaces) do
      add :postbot_key, :text
    end
  end
end
