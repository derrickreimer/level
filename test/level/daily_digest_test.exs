defmodule Level.DailyDigestTest do
  use Level.DataCase, async: true

  alias Level.DailyDigest
  alias Level.Digests
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.DueDigest
  alias Level.Schemas.PostLog
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

    test "does not include revoked users", %{
      now: now
    } do
      {:ok, %{space_user: %SpaceUser{id: space_user_id} = space_user}} =
        create_user_and_space(%{time_zone: "Etc/UTC"})

      Spaces.revoke_access(space_user)

      query = DailyDigest.due_query(now, now.hour - 1)
      results = Repo.all(query)
      refute Enum.any?(results, fn result -> result.space_user_id == space_user_id end)
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
      {:ok, _} = Digests.build(space_user, [], opts)

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

  describe "build_and_send/2" do
    test "skips when there is no inbox activity or other recent activity" do
      {:ok, %{space_user: space_user}} = create_user_and_space()

      due_digest = build_due_digest(space_user)

      assert [{:skip, ^due_digest}] =
               DailyDigest.build_and_send([due_digest], ~N[2018-11-01 10:00:00])
    end

    test "summarizes inbox activity when there are unread posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      post = create_unread_post(space_user, group)

      due_digest = build_due_digest(space_user)
      [{:ok, digest}] = DailyDigest.build_and_send([due_digest], ~N[2018-11-01 10:00:00])

      [inbox_section | _] = digest.sections
      assert inbox_section.summary =~ ~r/You have 1 unread post in your inbox/

      assert Enum.any?(inbox_section.posts, fn section_post ->
               section_post.id == post.id
             end)
    end

    test "summarizes inbox activity when there are unread and read posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      create_unread_post(space_user, group)
      create_read_post(space_user, group)

      due_digest = build_due_digest(space_user)
      [{:ok, digest}] = DailyDigest.build_and_send([due_digest], ~N[2018-11-01 10:00:00])

      [inbox_section | _] = digest.sections

      assert inbox_section.summary =~
               ~r/You have 1 unread post and 1 post you have already seen in your inbox/
    end

    test "summarizes inbox activity when there are only read posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      create_read_post(space_user, group)

      due_digest = build_due_digest(space_user)
      [{:ok, digest}] = DailyDigest.build_and_send([due_digest], ~N[2018-11-01 10:00:00])

      [inbox_section | _] = digest.sections
      assert inbox_section.summary =~ ~r/You have 1 post in your inbox/
    end

    test "summarizes other recent activity when there are posts" do
      {:ok, %{space_user: space_user, space: space}} = create_user_and_space()
      {:ok, %{space_user: another_user}} = create_space_member(space)
      {:ok, %{group: group}} = create_group(space_user)

      {:ok, %{post: post}} = create_post(another_user, group)

      due_digest = build_due_digest(space_user)
      [{:ok, digest}] = DailyDigest.build_and_send([due_digest], ~N[2018-11-01 10:00:00])

      [activity_section] = digest.sections

      assert activity_section.summary =~ ~r/Here are some recent messages from your Feed/

      assert Enum.any?(activity_section.posts, fn section_post ->
               section_post.id == post.id
             end)
    end

    test "skips recent activity when there are no posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space()

      # Add some inbox activity to prevent the digest from getting skipped
      {:ok, %{group: group}} = create_group(space_user)
      _post = create_unread_post(space_user, group)

      due_digest = build_due_digest(space_user)
      [{:ok, digest}] = DailyDigest.build_and_send([due_digest], ~N[2018-11-01 10:00:00])

      assert Enum.count(digest.sections) == 1
    end

    test "skips when there is no recent inbox activity or feed activity" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      # Mark the post as unread
      {:ok, _} = Posts.mark_as_unread(space_user, [post])

      # Clear out all log entries for the post
      Repo.delete_all(PostLog)

      # 3:00 local time
      now = ~N[2018-11-01 10:00:00] |> DateTime.from_naive!("Etc/UTC")

      # Log some activity > 24 hours ago (outside the range for the inbox section)
      {:ok, _} = PostLog.post_edited(post, space_user, Timex.shift(now, hours: -25))

      due_digest = build_due_digest(space_user)

      assert [{:skip, ^due_digest}] = DailyDigest.build_and_send([due_digest], now)
    end
  end

  defp build_due_digest(space_user) do
    %DueDigest{
      id: space_user.id,
      space_id: space_user.space_id,
      space_user_id: space_user.id,
      digest_key: "daily",
      hour: 0,
      time_zone: "America/Phoenix"
    }
  end

  defp create_unread_post(space_user, group) do
    {:ok, %{post: post}} = create_post(space_user, group)
    Posts.mark_as_unread(space_user, [post])
    post
  end

  defp create_read_post(space_user, group) do
    {:ok, %{post: post}} = create_post(space_user, group)
    Posts.mark_as_read(space_user, [post])
    post
  end
end
