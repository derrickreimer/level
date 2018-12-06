defmodule Level.DailyDigestTest do
  use Level.DataCase, async: true

  alias Level.DailyDigest
  alias Level.Digests
  alias Level.Repo
  alias Level.Schemas.DueDigest
  alias Level.Schemas.SpaceUser
  alias Level.Spaces

  describe "due_query/1" do
    setup do
      {:ok, now, 0} = DateTime.from_iso8601("2018-11-01T10:00:00Z")
      {:ok, %{now: now}}
    end

    test "includes users who have not yet received the digest and are due", %{
      now: now
    } do
      {:ok, %{space_user: %SpaceUser{id: space_user_id}}} =
        create_user_and_space(%{time_zone: "Etc/UTC"})

      query = DailyDigest.due_query(now, now.hour - 1)
      assert [%DueDigest{space_user_id: ^space_user_id}] = Repo.all(query)
    end

    test "does not include users that are not yet due", %{now: now} do
      {:ok, %{space_user: _}} = create_user_and_space(%{time_zone: "Etc/UTC"})

      query = DailyDigest.due_query(now, now.hour + 1)
      assert [] = Repo.all(query)
    end

    test "does not include users who have yet received the digest already", %{
      now: now
    } do
      {:ok, %{space_user: %SpaceUser{id: space_user_id} = space_user}} =
        create_user_and_space(%{time_zone: "Etc/UTC"})

      # Obtain the proper digest key
      query = DailyDigest.due_query(now, now.hour)
      [%DueDigest{space_user_id: ^space_user_id, digest_key: digest_key}] = Repo.all(query)

      # Build the digest
      opts = DailyDigest.digest_options(digest_key, DateTime.utc_now(), "Etc/UTC")
      {:ok, _} = Digests.build(space_user, opts)

      # Verify that the user no longer appears in the results
      query = DailyDigest.due_query(now, now.hour)
      assert [] = Repo.all(query)
    end

    test "does not include users with disabled digests", %{
      now: now
    } do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "Etc/UTC"})

      # Disable the digest
      Spaces.update_space_user(space_user, %{is_digest_enabled: false})

      query = DailyDigest.due_query(now, now.hour - 1)
      assert [] = Repo.all(query)
    end
  end
end
