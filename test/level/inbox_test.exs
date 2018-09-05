defmodule Level.InboxTest do
  use Level.DataCase, async: true

  alias Level.Groups
  alias Level.Inbox
  alias Level.Posts
  alias Level.Posts.PostLog
  alias Level.Repo

  describe "group_activity_query/1" do
    setup do
      create_user_and_space()
    end

    test "includes post log entries for groups the user belongs to", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      assert %PostLog{} =
               space_user
               |> Inbox.group_activity_query()
               |> Repo.get_by(post_id: post.id, event: "POST_CREATED")
    end

    test "does not include post log entries for groups the user doesn't belongs to", %{
      space_user: space_user
    } do
      {:ok, %{group: group, membership: %{group_user: group_user}}} = create_group(space_user)
      Groups.delete_group_membership(group, space_user, group_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      assert nil ==
               space_user
               |> Inbox.group_activity_query()
               |> Repo.get_by(post_id: post.id)
    end
  end

  describe "post_activity_query/1" do
    setup do
      create_user_and_space()
    end

    test "includes post log entries for posts the user is subscribed to", %{
      space_user: space_user
    } do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      assert %PostLog{} =
               space_user
               |> Inbox.post_activity_query()
               |> Repo.get_by(post_id: post.id, event: "POST_CREATED")
    end

    test "does not include post log entries for groups the user doesn't belongs to", %{
      space_user: space_user
    } do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      Posts.unsubscribe(space_user, [post])

      assert nil ==
               space_user
               |> Inbox.post_activity_query()
               |> Repo.get_by(post_id: post.id)
    end
  end
end
