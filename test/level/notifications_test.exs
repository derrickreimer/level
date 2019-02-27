defmodule Level.NotificationsTest do
  use Level.DataCase, async: true

  alias Level.Notifications
  alias Level.Schemas.Post
  alias Level.Schemas.PostReaction
  alias Level.Schemas.Reply
  alias Level.Schemas.ReplyReaction

  describe "record_post_created/2" do
    test "inserts a notification record" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      post = %Post{id: "abc"}
      {:ok, notification} = Notifications.record_post_created(space_user, post)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "POST_CREATED"
      assert notification.data == %{"post_id" => "abc"}
    end
  end

  describe "record_reply_created/2" do
    test "inserts a notification record" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      reply = %Reply{id: "xyz", post_id: "abc"}
      {:ok, notification} = Notifications.record_reply_created(space_user, reply)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "REPLY_CREATED"
      assert notification.data == %{"post_id" => "abc", "reply_id" => "xyz"}
    end
  end

  describe "record_post_closed/2" do
    test "inserts a notification record" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      post = %Post{id: "abc"}
      {:ok, notification} = Notifications.record_post_closed(space_user, post)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "POST_CLOSED"
      assert notification.data == %{"post_id" => "abc"}
    end
  end

  describe "record_post_reopened/2" do
    test "inserts a notification record" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      post = %Post{id: "abc"}
      {:ok, notification} = Notifications.record_post_reopened(space_user, post)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "POST_REOPENED"
      assert notification.data == %{"post_id" => "abc"}
    end
  end

  describe "record_post_reaction_created/2" do
    test "inserts a notification record" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      reaction = %PostReaction{id: "xyz", post_id: "abc"}
      {:ok, notification} = Notifications.record_post_reaction_created(space_user, reaction)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "POST_REACTION_CREATED"
      assert notification.data == %{"post_id" => "abc", "post_reaction_id" => "xyz"}
    end
  end

  describe "record_reply_reaction_created/2" do
    test "inserts a notification record" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      reaction = %ReplyReaction{id: "xyz", post_id: "abc"}
      {:ok, notification} = Notifications.record_reply_reaction_created(space_user, reaction)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "REPLY_REACTION_CREATED"
      assert notification.data == %{"post_id" => "abc", "reply_reaction_id" => "xyz"}
    end
  end

  describe "dismiss/2" do
    test "transitions notifications to dismissed" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      post_id = post.id

      {:ok, _} = Notifications.record_post_created(space_user, post)
      {:ok, _} = Notifications.record_post_closed(space_user, post)

      {:ok, [%Post{id: ^post_id}]} = Notifications.dismiss(space_user, [post])

      notifications = Notifications.list(space_user, post)
      assert Enum.count(notifications) == 2

      assert Enum.all?(notifications, fn notification ->
               notification.state == "DISMISSED"
             end)
    end
  end
end
