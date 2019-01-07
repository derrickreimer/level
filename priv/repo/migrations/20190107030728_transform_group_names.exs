defmodule Level.Repo.Migrations.TransformGroupNames do
  use Ecto.Migration

  def up do
    execute "UPDATE groups SET name = regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9-]', '-', 'g');"
  end

  def down do
  end
end
