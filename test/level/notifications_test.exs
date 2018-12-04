defmodule Level.NotificationsTest do
  use Level.DataCase, async: true

  alias Level.Notifications
  alias Level.Schemas.Post
  alias Level.Schemas.Reply

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
end
