defmodule Level.Repo.Migrations.CreateDigestSections do
  use Ecto.Migration

  def change do
    create table(:digest_sections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :space_id, references(:spaces, on_delete: :nothing, type: :binary_id), null: false
      add :digest_id, references(:digests, on_delete: :nothing, type: :binary_id), null: false
      add :title, :text, null: false
      add :summary, :text
      add :summary_html, :text
      add :link_text, :text
      add :link_url, :text
      add :rank, :integer

      timestamps()
    end
  end
end
