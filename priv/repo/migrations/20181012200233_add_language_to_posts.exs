defmodule Level.Repo.Migrations.AddLanguageToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :language, :text, null: false, default: "english"
    end

    alter table(:replies) do
      add :language, :text, null: false, default: "english"
    end
  end
end
