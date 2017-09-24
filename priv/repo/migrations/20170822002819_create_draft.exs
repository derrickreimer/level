defmodule Level.Repo.Migrations.CreateDraft do
  use Ecto.Migration

  def change do
    create table(:drafts, primary_key: false) do
      add :id, :bigint, default: fragment("next_global_id()"), null: false, primary_key: true
      add :team_id, references(:teams, on_delete: :nothing, type: :bigint), null: false
      add :user_id, references(:users, on_delete: :nothing, type: :bigint), null: false
      add :recipient_ids, {:array, :string}, null: false, default: []
      add :subject, :string, null: false, default: ""
      add :body, :text, null: false, default: ""
      add :is_truncated, :boolean, null: false, default: false

      timestamps()
    end

    create index(:drafts, [:id])
    create index(:drafts, [:user_id])
  end
end
