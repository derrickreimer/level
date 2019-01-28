defmodule Level.Repo.Migrations.SimplifyOverrideNamesOnPosts do
  use Ecto.Migration

  def up do
    rename(table("posts"), :author_display_name, to: :display_name)
    rename(table("posts"), :avatar_initials, to: :initials)
  end

  def down do
    rename(table("posts"), :display_name, to: :author_display_name)
    rename(table("posts"), :initials, to: :avatar_initials)
  end
end
