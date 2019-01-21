defmodule Level.PostsTest do
  use Level.DataCase, async: true

  import Ecto.Query

  alias Ecto.Changeset
  alias Level.Groups
  alias Level.Notifications
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.File
  alias Level.Schemas.Group
  alias Level.Schemas.Notification
  alias Level.Schemas.Post
  alias Level.Schemas.PostLog
  alias Level.Schemas.PostReaction
  alias Level.Schemas.PostVersion
  alias Level.Schemas.PostView
  alias Level.Schemas.Reply
  alias Level.Schemas.ReplyReaction
  alias Level.Schemas.SpaceUser
  alias Level.Schemas.User

  describe "posts_base_query/1 with users" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, Map.put(result, :group, group)}
    end

    test "should not include posts not in the user's spaces", %{
      space_user: space_user,
      group: group
    } do
      {:ok, %{post: %Post{id: post_id}}} = create_post(space_user, group)
      {:ok, outside_user} = create_user()

      result =
        outside_user
        |> Posts.posts_base_query()
        |> Repo.get_by(id: post_id)

      assert result == nil
    end

    test "should not include posts in private groups the user cannot access", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, group} = Groups.update_group(group, %{is_private: true})
      {:ok, %{post: %Post{id: post_id}}} = create_post(space_user, group)
      {:ok, %{user: another_user}} = create_space_member(space)

      result =
        another_user
        |> Posts.posts_base_query()
        |> Repo.get_by(id: post_id)

      assert result == nil
    end

    test "should include posts in private groups the user can access", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, group} = Groups.update_group(group, %{is_private: true})
      {:ok, %{post: %Post{id: post_id}}} = create_post(space_user, group)
      {:ok, %{user: another_user, space_user: another_space_user}} = create_space_member(space)
      :ok = Groups.subscribe(group, another_space_user)

      assert %Post{id: ^post_id} =
               another_user
               |> Posts.posts_base_query()
               |> Repo.get_by(id: post_id)
    end

    test "should include posts in public groups", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{post: %Post{id: post_id}}} = create_post(space_user, group)
      {:ok, %{user: another_user}} = create_space_member(space)

      assert %Post{id: ^post_id} =
               another_user
               |> Posts.posts_base_query()
               |> Repo.get_by(id: post_id)
    end

    test "should include posts sent directly to the user", %{
      levelbot: levelbot,
      space_user: space_user,
      user: user
    } do
      {:ok, %{post: %Post{id: post_id}}} = create_post(levelbot, space_user)

      assert %Post{id: ^post_id} =
               user
               |> Posts.posts_base_query()
               |> Repo.get_by(id: post_id)
    end

    test "should exclude posts sent directly to other users", %{
      space: space,
      levelbot: levelbot,
      space_user: space_user
    } do
      {:ok, %{post: %Post{id: post_id}}} = create_post(levelbot, space_user)
      {:ok, %{user: another_user}} = create_space_member(space)

      refute another_user
             |> Posts.posts_base_query()
             |> Repo.get_by(id: post_id)
    end

    test "should exclude deleted posts", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{post: %Post{id: post_id} = post}} = create_post(space_user, group)
      {:ok, %{user: another_user}} = create_space_member(space)

      post
      |> Changeset.change(state: "DELETED")
      |> Repo.update()

      refute another_user
             |> Posts.posts_base_query()
             |> Repo.get_by(id: post_id)
    end
  end

  describe "get_subscribers/1" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "includes subscribers", %{space: space, space_user: space_user, post: post} do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      Posts.subscribe(another_user, [post])

      {:ok, result} = Posts.get_subscribers(post)

      ids =
        result
        |> Enum.map(fn user -> user.id end)
        |> Enum.sort()

      assert ids == Enum.sort([space_user.id, another_user.id])
    end

    test "excludes unsubscribes", %{space_user: space_user, post: post} do
      Posts.unsubscribe(space_user, [post])
      assert {:ok, []} = Posts.get_subscribers(post)
    end
  end

  describe "create_post/2 with space user + group" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, Map.put(result, :group, group)}
    end

    test "creates a new post given valid params", %{space_user: space_user, group: group} do
      params = valid_post_params() |> Map.merge(%{body: "The body"})
      {:ok, %{post: post}} = Posts.create_post(space_user, group, params)
      assert post.space_user_id == space_user.id
      assert post.body == "The body"
    end

    test "puts the post in the given group", %{
      space_user: space_user,
      group: %Group{id: group_id} = group
    } do
      params = valid_post_params()
      {:ok, %{post: post}} = Posts.create_post(space_user, group, params)

      post = Repo.preload(post, :groups)
      assert [%Group{id: ^group_id} | _] = post.groups
    end

    test "subscribes the user to the post", %{space_user: space_user, group: group} do
      params = valid_post_params()
      {:ok, %{post: post}} = Posts.create_post(space_user, group, params)

      assert %{inbox: "EXCLUDED", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, space_user)
    end

    test "logs the event", %{space_user: space_user, group: group} do
      params = valid_post_params()
      {:ok, %{post: post, log: log}} = Posts.create_post(space_user, group, params)
      assert log.event == "POST_CREATED"
      assert log.space_user_id == space_user.id
      assert log.post_id == post.id
    end

    test "subscribes mentioned users and marks as unread", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{space_user: mentioned}} = create_space_member(space, %{handle: "tiff"})
      {:ok, %{space_user: another_mentioned}} = create_space_member(space, %{handle: "derrick"})

      params = valid_post_params() |> Map.merge(%{body: "Hey @tiff and @derrick"})
      {:ok, %{post: post}} = Posts.create_post(space_user, group, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, mentioned)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, another_mentioned)

      assert [%Notification{event: "POST_CREATED"}] = Notifications.list(mentioned, post)
    end

    test "does not subscribe mentioned users who cannot access the post", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{space_user: %SpaceUser{id: mentioned_id} = mentioned}} =
        create_space_member(space, %{handle: "tiff"})

      {:ok, group} = Groups.update_group(group, %{is_private: true})

      params = valid_post_params() |> Map.merge(%{body: "Hey @tiff"})

      {:ok, %{post: post, mentions: [%SpaceUser{id: ^mentioned_id}]}} =
        Posts.create_post(space_user, group, params)

      assert %{inbox: "EXCLUDED", subscription: "NOT_SUBSCRIBED"} =
               Posts.get_user_state(post, mentioned)
    end

    test "attaches file uploads", %{space_user: space_user, group: group} do
      {:ok, %File{id: file_id}} = create_file(space_user)
      params = valid_post_params() |> Map.merge(%{file_ids: [file_id]})
      {:ok, %{post: post}} = Posts.create_post(space_user, group, params)

      assert [%File{id: ^file_id}] =
               post
               |> Ecto.assoc(:files)
               |> Repo.all()
    end

    test "stores the locator", %{space_user: space_user, group: group} do
      locator_params = %{scope: "level", topic: "welcome_message", key: group.id}
      params = valid_post_params() |> Map.merge(%{locator: locator_params})
      {:ok, %{post: post, locator: locator}} = Posts.create_post(space_user, group, params)

      assert locator.post_id == post.id
      assert locator.scope == "level"
      assert locator.topic == "welcome_message"
      assert locator.key == group.id
    end

    test "adds to tagged groups", %{space_user: space_user, group: group} do
      {:ok, %{group: another_group}} = create_group(space_user, %{name: "my-group"})

      params =
        valid_post_params()
        |> Map.put(:body, "Hello #my-group")

      {:ok, %{post: post}} = Posts.create_post(space_user, group, params)

      post = Repo.preload(post, :groups)
      assert Enum.any?(post.groups, fn group -> group.id == another_group.id end)
    end

    test "returns errors given invalid params", %{space_user: space_user, group: group} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, :post, changeset, _} = Posts.create_post(space_user, group, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end
  end

  describe "create_post/2 with bot + direct recipient" do
    setup do
      {:ok, %{space: space} = result} = create_user_and_space()
      {:ok, %{space_user: recipient}} = create_space_member(space)
      {:ok, Map.put(result, :recipient, recipient)}
    end

    test "creates a new post given valid params", %{levelbot: space_bot, recipient: recipient} do
      params = valid_post_params() |> Map.merge(%{body: "The body"})
      {:ok, %{post: post}} = Posts.create_post(space_bot, recipient, params)
      assert post.space_bot_id == space_bot.id
      assert post.body == "The body"
    end

    test "subscribes the recipient to the post", %{levelbot: space_bot, recipient: recipient} do
      params = valid_post_params()
      {:ok, %{post: post}} = Posts.create_post(space_bot, recipient, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, recipient)
    end

    test "stores the locator", %{levelbot: space_bot, recipient: recipient} do
      locator_params = %{scope: "level", topic: "welcome_message", key: recipient.id}
      params = valid_post_params() |> Map.merge(%{locator: locator_params})
      {:ok, %{post: post, locator: locator}} = Posts.create_post(space_bot, recipient, params)

      assert locator.post_id == post.id
      assert locator.scope == "level"
      assert locator.topic == "welcome_message"
      assert locator.key == recipient.id
    end

    test "returns errors given invalid params", %{levelbot: space_bot, recipient: recipient} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, :post, changeset, _} = Posts.create_post(space_bot, recipient, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end
  end

  describe "update_post/3" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group, %{body: "Old body"})
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "does not allow a non-author to edit", %{space: space, post: post} do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      assert {:error, :unauthorized} =
               Posts.update_post(another_user, post, %{body: "Hijacking this post!"})
    end

    test "allows the original author to edit", %{space_user: space_user, post: post} do
      {:ok, result} = Posts.update_post(space_user, post, %{body: "New body"})
      assert result.updated_post.body == "New body"
    end

    test "stores a version entry for the previous version", %{space_user: space_user, post: post} do
      {:ok, _} = Posts.update_post(space_user, post, %{body: "New body"})

      query =
        from pv in PostVersion,
          where: pv.post_id == ^post.id

      assert [%PostVersion{body: "Old body"}] = Repo.all(query)
    end

    test "logs the event", %{space_user: space_user, post: post} do
      {:ok, %{log: log}} = Posts.update_post(space_user, post, %{body: "New body"})
      assert log.event == "POST_EDITED"
      assert log.space_user_id == space_user.id
      assert log.post_id == post.id
    end
  end

  describe "subscribe/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "subscribes the user to the post", %{
      space: space,
      post: post
    } do
      {:ok, %{space_user: another_space_user}} = create_space_member(space)
      {:ok, [^post]} = Posts.subscribe(another_space_user, [post])
      assert %{subscription: "SUBSCRIBED"} = Posts.get_user_state(post, another_space_user)
    end

    test "ignores repeated subscribes", %{space_user: space_user, post: post} do
      assert %{subscription: "SUBSCRIBED"} = Posts.get_user_state(post, space_user)
      assert {:ok, [^post]} = Posts.subscribe(space_user, [post])
    end
  end

  describe "create_reply/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "creates a new reply given valid params", %{space_user: space_user, post: post} do
      params = valid_reply_params() |> Map.merge(%{body: "The body"})
      {:ok, %{reply: reply}} = Posts.create_reply(space_user, post, params)
      assert reply.space_user_id == space_user.id
      assert reply.body == "The body"
    end

    test "subscribes the user to the post", %{space_user: space_user, post: post} do
      {:ok, _} = Posts.unsubscribe(space_user, [post])
      params = valid_reply_params()
      {:ok, %{reply: _reply}} = Posts.create_reply(space_user, post, params)
      assert %{subscription: "SUBSCRIBED"} = Posts.get_user_state(post, space_user)
    end

    test "record mentions", %{space: space, space_user: space_user, post: post} do
      {:ok, %{space_user: %SpaceUser{id: mentioned_id}}} =
        create_space_member(space, %{handle: "tiff"})

      params = valid_reply_params() |> Map.merge(%{body: "Hey @tiff"})

      assert {:ok, %{mentions: [%SpaceUser{id: ^mentioned_id}]}} =
               Posts.create_reply(space_user, post, params)
    end

    test "logs the event", %{space_user: space_user, post: post, group: group} do
      params = valid_reply_params()
      {:ok, %{reply: reply, log: log}} = Posts.create_reply(space_user, post, params)
      assert log.event == "REPLY_CREATED"
      assert log.space_user_id == space_user.id
      assert log.group_id == group.id
      assert log.post_id == post.id
      assert log.reply_id == reply.id
    end

    test "records a view", %{space_user: space_user, post: post} do
      params = valid_reply_params()
      {:ok, %{reply: reply, post_view: post_view}} = Posts.create_reply(space_user, post, params)
      assert post_view.post_id == post.id
      assert post_view.last_viewed_reply_id == reply.id
    end

    test "subscribes mentioned users and marks as unread", %{
      space: space,
      space_user: space_user,
      post: post
    } do
      {:ok, %{space_user: %SpaceUser{id: mentioned_id} = mentioned}} =
        create_space_member(space, %{handle: "tiff"})

      params = valid_reply_params() |> Map.merge(%{body: "Hey @tiff"})

      {:ok, %{mentions: [%SpaceUser{id: ^mentioned_id}]}} =
        Posts.create_reply(space_user, post, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, mentioned)

      assert [%Notification{event: "REPLY_CREATED"}] = Notifications.list(mentioned, post)
    end

    test "does not subscribe mentioned users who cannot access the post", %{
      space: space,
      space_user: space_user,
      post: post,
      group: group
    } do
      {:ok, %{space_user: %SpaceUser{id: mentioned_id} = mentioned}} =
        create_space_member(space, %{handle: "tiff"})

      {:ok, _} = Groups.update_group(group, %{is_private: true})

      params = valid_post_params() |> Map.merge(%{body: "Hey @tiff"})

      {:ok, %{mentions: [%SpaceUser{id: ^mentioned_id}]}} =
        Posts.create_reply(space_user, post, params)

      assert %{inbox: "EXCLUDED", subscription: "NOT_SUBSCRIBED"} =
               Posts.get_user_state(post, mentioned)
    end

    test "marks as unread for subscribers", %{space: space, space_user: space_user, post: post} do
      {:ok, %{space_user: another_subscriber}} = create_space_member(space)
      Posts.subscribe(another_subscriber, [post])
      {:ok, _} = Posts.create_reply(space_user, post, valid_reply_params())
      assert %{inbox: "UNREAD"} = Posts.get_user_state(post, another_subscriber)
    end

    test "attaches file uploads", %{space_user: space_user, post: post} do
      {:ok, %File{id: file_id}} = create_file(space_user)
      params = valid_reply_params() |> Map.merge(%{file_ids: [file_id]})
      {:ok, %{reply: reply}} = Posts.create_reply(space_user, post, params)

      assert [%File{id: ^file_id}] =
               reply
               |> Ecto.assoc(:files)
               |> Repo.all()
    end

    test "returns errors given invalid params", %{space_user: space_user, post: post} do
      params = valid_reply_params() |> Map.merge(%{body: nil})
      {:error, :reply, changeset, _} = Posts.create_reply(space_user, post, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end

    test "marks the reply as viewed by the author", %{space_user: space_user, post: post} do
      {:ok, %{reply: reply}} = Posts.create_reply(space_user, post, valid_reply_params())
      assert Posts.viewed_reply?(reply, space_user)
    end
  end

  describe "record_view/3" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "creates a post view record with last viewed reply", %{
      space_user: space_user,
      post: post
    } do
      {:ok, %{reply: %Reply{id: reply_id} = reply}} = create_reply(space_user, post)

      assert {:ok, %PostView{last_viewed_reply_id: ^reply_id}} =
               Posts.record_view(post, space_user, reply)
    end
  end

  describe "record_view/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "creates a post view record with null last viewed reply", %{
      space_user: space_user,
      post: post
    } do
      assert {:ok, %PostView{last_viewed_reply_id: nil}} = Posts.record_view(post, space_user)
    end
  end

  describe "record_reply_views/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "marks the replies as read for the given user", %{
      space: space,
      space_user: space_user,
      post: post
    } do
      {:ok, %{reply: reply}} = create_reply(space_user, post)
      {:ok, %{reply: another_reply}} = create_reply(space_user, post)
      {:ok, %{space_user: another_member}} = create_space_member(space)

      refute Posts.viewed_reply?(reply, another_member)
      refute Posts.viewed_reply?(another_reply, another_member)

      {:ok, returned_replies} = Posts.record_reply_views(another_member, [reply, another_reply])

      assert Posts.viewed_reply?(reply, another_member)
      assert Posts.viewed_reply?(another_reply, another_member)
      assert returned_replies == [reply, another_reply]
    end
  end

  describe "render_body/1" do
    setup do
      {:ok, %{viewer: %User{handle: "derrick"}}}
    end

    test "converts markdown to html", %{viewer: viewer} do
      assert Posts.render_body("Foo", viewer) == {:ok, "<p>Foo</p>"}
    end

    test "emboldens mentions", %{viewer: viewer} do
      assert Posts.render_body("@tiff Hey", viewer) ==
               {:ok, "<p><strong class=\"user-mention\">@tiff</strong> Hey</p>"}
    end
  end

  describe "attach_files/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "attaches the given uploads to the post", %{space_user: space_user, post: post} do
      {:ok, %File{id: file_id} = upload} = create_file(space_user)
      {:ok, [%File{id: ^file_id}]} = Posts.attach_files(post, [upload])

      assert [%File{id: ^file_id}] =
               post
               |> Ecto.assoc(:files)
               |> Repo.all()
    end
  end

  describe "close_post/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "marks the post as closed", %{post: post, space_user: space_user} do
      assert post.state == "OPEN"
      {:ok, %{post: closed_post}} = Posts.close_post(space_user, post)
      assert closed_post.id == post.id
      assert closed_post.state == "CLOSED"
    end

    test "dismissed the post from the closer's inbox and records notifications", %{
      space: space,
      post: post,
      space_user: space_user
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      {:ok, _} = Posts.subscribe(space_user, [post])
      {:ok, _} = Posts.subscribe(another_user, [post])

      {:ok, _} = Posts.mark_as_unread(space_user, [post])
      {:ok, _} = Posts.mark_as_unread(another_user, [post])

      {:ok, _} = Posts.close_post(space_user, post)

      assert %{inbox: "DISMISSED"} = Posts.get_user_state(post, space_user)
      assert %{inbox: "UNREAD"} = Posts.get_user_state(post, another_user)

      assert [] = Notifications.list(space_user, post)
      assert [%Notification{event: "POST_CLOSED"}] = Notifications.list(another_user, post)
    end
  end

  describe "reopen_post/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, Map.merge(result, %{group: group, post: post})}
    end

    test "marks the post as closed", %{post: post, space_user: space_user} do
      {:ok, %{post: closed_post}} = Posts.close_post(space_user, post)
      {:ok, %{post: reopened_post}} = Posts.reopen_post(space_user, closed_post)

      assert reopened_post.id == post.id
      assert reopened_post.state == "OPEN"
    end

    test "records notifications", %{
      space: space,
      post: post,
      space_user: space_user
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      {:ok, _} = Posts.subscribe(another_user, [post])
      {:ok, _} = Posts.close_post(space_user, post)
      {:ok, _} = Posts.reopen_post(space_user, post)

      assert Enum.any?(Notifications.list(another_user, post), fn notification ->
               notification.event == "POST_REOPENED"
             end)
    end
  end

  describe "mark_as_read/2" do
    test "sets the inbox state to read and dismisses notifications" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      Notifications.record_post_created(space_user, post)
      assert %{inbox: "EXCLUDED"} = Posts.get_user_state(post, space_user)

      Posts.mark_as_read(space_user, [post])
      assert %{inbox: "READ"} = Posts.get_user_state(post, space_user)

      notifications = Notifications.list(space_user, post)

      assert Enum.all?(notifications, fn notification ->
               notification.state == "DISMISSED"
             end)
    end
  end

  describe "create_post_reaction/2" do
    test "creates a reaction and handles duplicates" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      refute Posts.reacted?(space_user, post)

      {:ok, _} = Posts.create_post_reaction(space_user, post)

      assert Posts.reacted?(space_user, post)

      assert Repo.get_by(PostLog,
               space_user_id: space_user.id,
               post_id: post.id,
               event: "POST_REACTION_CREATED"
             )

      # Duplicate reaction
      space_user_id = space_user.id
      post_id = post.id

      assert {:ok, %PostReaction{space_user_id: ^space_user_id, post_id: ^post_id}} =
               Posts.create_post_reaction(space_user, post)
    end
  end

  describe "delete_post_reaction/2" do
    test "deletes the reaction if one exists" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, reaction} = Posts.create_post_reaction(space_user, post)

      assert Posts.reacted?(space_user, post)

      {:ok, deleted_reaction} = Posts.delete_post_reaction(space_user, post)
      assert deleted_reaction.id == reaction.id
      refute Posts.reacted?(space_user, post)
    end

    test "returns an error if the user had not reacted" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      refute Posts.reacted?(space_user, post)

      {:error, "Reaction not found"} = Posts.delete_post_reaction(space_user, post)
    end
  end

  describe "create_reply_reaction/2" do
    test "creates a reaction and handles duplicates" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, %{reply: reply}} = create_reply(space_user, post)

      refute Posts.reacted?(space_user, reply)

      {:ok, _} = Posts.create_reply_reaction(space_user, reply)

      assert Posts.reacted?(space_user, reply)

      assert Repo.get_by(PostLog,
               space_user_id: space_user.id,
               post_id: post.id,
               reply_id: reply.id,
               event: "REPLY_REACTION_CREATED"
             )

      # Duplicate reaction
      space_user_id = space_user.id
      reply_id = reply.id

      assert {:ok, %ReplyReaction{space_user_id: ^space_user_id, reply_id: ^reply_id}} =
               Posts.create_reply_reaction(space_user, reply)
    end
  end

  describe "delete_reply_reaction/2" do
    test "deletes the reaction if one exists" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, %{reply: reply}} = create_reply(space_user, post)

      {:ok, reaction} = Posts.create_reply_reaction(space_user, reply)

      assert Posts.reacted?(space_user, reply)

      {:ok, deleted_reaction} = Posts.delete_reply_reaction(space_user, reply)
      assert deleted_reaction.id == reaction.id
      refute Posts.reacted?(space_user, reply)
    end

    test "returns an error if the user had not reacted" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, %{reply: reply}} = create_reply(space_user, post)

      refute Posts.reacted?(space_user, reply)

      {:error, "Reaction not found"} = Posts.delete_reply_reaction(space_user, reply)
    end
  end
end
