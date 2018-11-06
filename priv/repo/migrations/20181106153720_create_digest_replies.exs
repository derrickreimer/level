defmodule Level.Repo.Migrations.CreateDigestReplies do
  use Ecto.Migration

  def change do
    create table(:digest_replies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :digest_id, references(:digests, on_delete: :nothing, type: :binary_id), null: false

      add :digest_post_id, references(:digest_posts, on_delete: :nothing, type: :binary_id),
        null: false

      add :reply_id, references(:replies, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end
  end
end
