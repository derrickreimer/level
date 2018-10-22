defmodule Level.Repo.Migrations.CreatePostLocators do
  use Ecto.Migration

  def change do
    create table(:post_locators, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :scope, :text, null: false
      add :topic, :text, null: false
      add :key, :text, null: false

      timestamps()
    end

    create unique_index(:post_locators, [:space_id, :scope, :topic, :key])
  end
end
