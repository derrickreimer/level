defmodule Level.Posts.QueryTest do
  use Level.DataCase, async: true

  alias Level.Groups
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

      assert query_includes?(query, post)
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

      refute query_includes?(query, post)
    end
  end

  describe "where_last_active_after/2" do
    test "includes posts where activity occurred in range" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      # Clear out all log entries for the post
      Repo.delete_all(PostLog)

      # Log some activity
      {:ok, _} = PostLog.post_edited(post, space_user, ~N[2018-11-01 05:00:00])

      query =
        space_user
        |> Posts.Query.base_query()
        |> Posts.Query.select_last_activity_at()
        |> Posts.Query.where_last_active_after(~N[2018-11-01 04:00:00])

      assert query_includes?(query, post)
    end

    test "excludes posts where activity occurred outside range" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      # Clear out all log entries for the post
      Repo.delete_all(PostLog)

      # Log some activity
      {:ok, _} = PostLog.post_edited(post, space_user, ~N[2018-11-01 03:00:00])

      query =
        space_user
        |> Posts.Query.base_query()
        |> Posts.Query.select_last_activity_at()
        |> Posts.Query.where_last_active_after(~N[2018-11-01 04:00:00])

      refute query_includes?(query, post)
    end
  end

  describe "where_is_following_and_not_subscribed/1" do
    test "does not include subscribed posts" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      Posts.subscribe(space_user, [post])

      query =
        space_user
        |> Posts.Query.base_query()
        |> Posts.Query.where_is_following_and_not_subscribed()

      refute query_includes?(query, post)
    end

    test "includes unsubscribed posts in groups the user belongs to" do
      {:ok, %{space_user: space_user}} = create_user_and_space(%{time_zone: "America/Phoenix"})
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      Posts.unsubscribe(space_user, [post])

      query =
        space_user
        |> Posts.Query.base_query()
        |> Posts.Query.where_is_following_and_not_subscribed()

      assert query_includes?(query, post)
    end

    test "includes posts in groups the user belongs to the user was never subscribed to" do
      {:ok, %{space_user: space_user, space: space}} =
        create_user_and_space(%{time_zone: "America/Phoenix"})

      {:ok, %{space_user: another_user}} = create_space_member(space)

      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      Groups.subscribe(group, another_user)

      query =
        another_user
        |> Posts.Query.base_query()
        |> Posts.Query.where_is_following_and_not_subscribed()

      assert query_includes?(query, post)
    end
  end

  def query_includes?(query, record) do
    results = Repo.all(query)
    Enum.any?(results, fn result -> result.id == record.id end)
  end
end
