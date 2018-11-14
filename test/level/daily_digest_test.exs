defmodule Level.DailyDigestTest do
  use Level.DataCase, async: true

  alias Level.DailyDigest
  alias Level.DailyDigest.Sendable
  alias Level.Digests
  alias Level.Repo
  alias Level.Schemas.SpaceUser

  describe "sendable_query/1" do
    setup do
      {:ok, now, 0} = DateTime.from_iso8601("2018-11-01T10:00:00Z")
      {:ok, %{now: now}}
    end

    test "includes users who have not yet received the digest and are due", %{
      now: now
    } do
      {:ok, %{space_user: %SpaceUser{id: space_user_id}}} =
        create_user_and_space(%{time_zone: "Etc/UTC"})

      query = DailyDigest.sendable_query(now, now.hour - 1)
      assert [%Sendable{id: ^space_user_id}] = Repo.all(query)
    end

    test "does not include users that are not yet due", %{now: now} do
      {:ok, %{space_user: _}} = create_user_and_space(%{time_zone: "Etc/UTC"})

      query = DailyDigest.sendable_query(now, now.hour + 1)
      assert [] = Repo.all(query)
    end

    test "does not include users who have yet received the digest already", %{
      now: now
    } do
      {:ok, %{space_user: %SpaceUser{id: space_user_id} = space_user}} =
        create_user_and_space(%{time_zone: "Etc/UTC"})

      # Obtain the proper digest key
      query = DailyDigest.sendable_query(now, now.hour)
      [%Sendable{id: ^space_user_id, digest_key: digest_key}] = Repo.all(query)

      # Build the digest
      opts = DailyDigest.options_for(digest_key, DateTime.utc_now(), "Etc/UTC")
      {:ok, _} = Digests.build(space_user, opts)

      # Verify that the user no longer appears in the results
      query = DailyDigest.sendable_query(now, now.hour)
      assert [] = Repo.all(query)
    end
  end
end
