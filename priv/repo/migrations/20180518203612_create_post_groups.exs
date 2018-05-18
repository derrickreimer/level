defmodule Level.Repo.Migrations.CreatePostGroups do
  use Ecto.Migration

  def change do
    create table(:post_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id), null: false
      add :group_id, references(:groups, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:post_groups, [:post_id, :group_id])
  end
end
