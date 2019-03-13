defmodule Level.NotificationsTest do
  use Level.DataCase, async: true

  alias Level.Notifications
  alias Level.Repo
  alias Level.Schemas.Notification
  alias Level.Schemas.Post
  alias Level.Schemas.PostReaction
  alias Level.Schemas.Reply
  alias Level.Schemas.ReplyReaction
  alias Level.Schemas.SpaceUser

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
      actor = %SpaceUser{id: "zzz"}
      post = %Post{id: "abc"}
      {:ok, notification} = Notifications.record_post_closed(space_user, post, actor)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "POST_CLOSED"

      assert notification.data == %{
               "post_id" => "abc",
               "actor_id" => "zzz",
               "actor_type" => "SpaceUser"
             }
    end
  end

  describe "record_post_reopened/2" do
    test "inserts a notification record" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      actor = %SpaceUser{id: "zzz"}
      post = %Post{id: "abc"}
      {:ok, notification} = Notifications.record_post_reopened(space_user, post, actor)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "POST_REOPENED"

      assert notification.data == %{
               "post_id" => "abc",
               "actor_id" => "zzz",
               "actor_type" => "SpaceUser"
             }
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
      reaction = %ReplyReaction{id: "xyz", post_id: "abc", reply_id: "bbb"}
      {:ok, notification} = Notifications.record_reply_reaction_created(space_user, reaction)

      assert notification.topic == "post:abc"
      assert notification.state == "UNDISMISSED"
      assert notification.event == "REPLY_REACTION_CREATED"

      assert notification.data == %{
               "post_id" => "abc",
               "reply_id" => "bbb",
               "reply_reaction_id" => "xyz"
             }
    end
  end

  describe "dismiss_topic/2" do
    test "transitions notifications to dismissed" do
      {:ok, %{user: user, space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      post_id = post.id
      topic = "post:#{post_id}"

      {:ok, _} = Notifications.record_post_created(space_user, post)
      {:ok, _} = Notifications.record_post_closed(space_user, post, space_user)

      {:ok, ^topic} = Notifications.dismiss_topic(user, topic)

      notifications = Notifications.list(space_user, post)
      assert Enum.count(notifications) == 2

      assert Enum.all?(notifications, fn notification ->
               notification.state == "DISMISSED"
             end)
    end

    test "does not touch timestamp on already dismissed notifications" do
      {:ok, %{user: user, space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      post_id = post.id
      topic = "post:#{post_id}"
      earlier_time = ~N[2018-11-01 10:00:00.000000]
      now = ~N[2018-11-02 10:00:00.000000]

      {:ok, notification} = Notifications.record_post_created(space_user, post)
      {:ok, ^topic} = Notifications.dismiss_topic(user, topic, earlier_time)
      {:ok, ^topic} = Notifications.dismiss_topic(user, topic, now)

      updated_notification = Repo.get(Notification, notification.id)
      assert updated_notification.updated_at == earlier_time
    end
  end
end
