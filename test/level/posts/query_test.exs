defmodule Level.Posts.QueryTest do
  use Level.DataCase, async: true

  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.PostLog

  # Note on time zones: America/Phoenix (-7:00) does not currently observe
  # daylight saving time, which makes it a good zone to use for testing offset logic.

  describe "where_last_active_today/2" do
    test "includes posts where activity occurred today (in user's TZ)" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      # Clear out all log entries for the post
      Repo.delete_all(PostLog)

      # 3:00
      now = ~N[2018-11-01 10:00:00]

      # Log some activity
      {:ok, _} = PostLog.post_edited(post, space_user, now)

      query =
        space_user
        |> Posts.Query.base_query()
        |> Posts.Query.select_last_activity_at()
        |> Posts.Query.where_last_active_today(now)

      results = Repo.all(query)

      assert Enum.any?(results, fn result -> result.id == post.id end)
    end

    test "excludes posts where activity occurred before today" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      # Clear out all log entries for the post
      Repo.delete_all(PostLog)

      # 3:00
      now = ~N[2018-11-01 10:00:00]

      # Log some past activity
      {:ok, _} = PostLog.post_edited(post, space_user, ~N[2018-11-01 05:00:00])

      query =
        space_user
        |> Posts.Query.base_query()
        |> Posts.Query.select_last_activity_at()
        |> Posts.Query.where_last_active_today(now)

      results = Repo.all(query)

      refute Enum.any?(results, fn result -> result.id == post.id end)
    end
  end
end
