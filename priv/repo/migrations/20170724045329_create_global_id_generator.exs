defmodule Bridge.Repo.Migrations.CreateGlobalIdGenerator do
  use Ecto.Migration

  def up do
    execute "CREATE SEQUENCE global_id_seq"

    execute """
    CREATE OR REPLACE FUNCTION next_global_id(OUT result bigint) AS $$
    DECLARE
        our_epoch bigint := 1501268767000;
        seq_id bigint;
        now_millis bigint;
        shard_id int := 1;
    BEGIN
        SELECT nextval('global_id_seq') % 1024 INTO seq_id;

        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
        result := (now_millis - our_epoch) << 23;
        result := result | (shard_id << 10);
        result := result | (seq_id);
    END;
    $$ LANGUAGE PLPGSQL;
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS next_global_id"
    execute "DROP SEQUENCE global_id_seq"
  end
end
