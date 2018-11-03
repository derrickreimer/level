defmodule Level.Repo.Migrations.UpdateGroupStatePartialIndex do
  use Ecto.Migration

  def up do
    drop index(:groups, [:space_id, "lower(name)"], name: :groups_unique_names_when_open)

    create(
      unique_index(
        :groups,
        [:space_id, "lower(name)"],
        where: "not state = 'DELETED'",
        name: :groups_unique_names_when_undeleted
      )
    )
  end

  def down do
    drop index(:groups, [:space_id, "lower(name)"], name: :groups_unique_names_when_undeleted)

    create(
      unique_index(
        :groups,
        [:space_id, "lower(name)"],
        where: "state = 'OPEN'",
        name: :groups_unique_names_when_open
      )
    )
  end
end
