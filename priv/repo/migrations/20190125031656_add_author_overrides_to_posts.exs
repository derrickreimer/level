defmodule Level.Repo.Migrations.AddAuthorOverridesToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :author_display_name, :text
      add :avatar_initials, :text
      add :avatar_color, :text
    end
  end
end
