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
      {:ok, %{space_user: space_user} = result} = create_user_and_space(%{handle: "derrick"})
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
      {:ok, group} = Groups.privatize(group)
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
      {:ok, group} = Groups.privatize(group)
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
      user: user
    } do
      {:ok, %{post: %Post{id: post_id}}} =
        Posts.create_post(levelbot, %{body: "Hello @derrick", display_name: "Level"})

      assert %Post{id: ^post_id} =
               user
               |> Posts.posts_base_query()
               |> Repo.get_by(id: post_id)
    end

    test "should exclude posts sent directly to other users", %{
      space: space,
      levelbot: levelbot
    } do
      {:ok, %{post: %Post{id: post_id}}} =
        Posts.create_post(levelbot, %{body: "Hello @derrick", display_name: "Level"})

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

  describe "create_post/2 with space user" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user, %{name: "room"})
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

    test "loops in mentioned users who formerly did not have access", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{space_user: %SpaceUser{id: mentioned_id} = mentioned}} =
        create_space_member(space, %{handle: "tiff"})

      {:ok, group} = Groups.update_group(group, %{is_private: true})

      params = valid_post_params() |> Map.merge(%{body: "Hey @tiff"})

      {:ok, %{post: post, mentions: %{space_users: [%SpaceUser{id: ^mentioned_id}]}}} =
        Posts.create_post(space_user, group, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, mentioned)
    end

    test "subscribes channel watchers", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      Groups.watch(group, another_user)

      params = valid_post_params()
      {:ok, %{post: post}} = Posts.create_post(space_user, group, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, another_user)
    end

    test "does not put in author's inbox when author is watching the channel", %{
      space_user: author,
      group: group
    } do
      Groups.watch(group, author)

      params = valid_post_params()
      {:ok, %{post: post}} = Posts.create_post(author, group, params)

      assert %{inbox: "EXCLUDED", subscription: "SUBSCRIBED"} = Posts.get_user_state(post, author)
    end

    test "handles channel mentions", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{group: %Group{id: another_group_id} = another_group}} =
        create_group(space_user, %{name: "devs"})

      {:ok, %{space_user: another_user}} = create_space_member(space)
      Groups.subscribe(another_group, another_user)

      params = valid_post_params() |> Map.merge(%{body: "Hey @#devs"})

      assert {:ok, %{post: post, mentions: %{groups: [%Group{id: ^another_group_id}]}}} =
               Posts.create_post(space_user, group, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, another_user)
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

    test "handles duplicate tagged groups", %{space_user: space_user, group: group} do
      params =
        valid_post_params()
        |> Map.put(:body, "Hello #room")

      assert {:ok, %{post: post}} = Posts.create_post(space_user, group, params)
    end

    test "subscribes the given recipients", %{space: space, space_user: space_user} do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      params =
        valid_post_params()
        |> Map.put(:body, "Hello")
        |> Map.put(:recipient_ids, [another_user.id])

      {:ok, %{post: post}} = Posts.create_post(space_user, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, another_user)
    end

    test "returns errors given invalid params", %{space_user: space_user, group: group} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, :post, changeset, _} = Posts.create_post(space_user, group, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end
  end

  describe "create_post/2 with bot" do
    setup do
      {:ok, %{space: space} = result} = create_user_and_space()
      {:ok, %{space_user: recipient}} = create_space_member(space, %{handle: "bobby"})
      {:ok, Map.put(result, :recipient, recipient)}
    end

    test "creates a new post given valid params", %{levelbot: space_bot} do
      params = valid_post_params() |> Map.merge(%{body: "Hi @bobby"})
      {:ok, %{post: post}} = Posts.create_post(space_bot, params)
      assert post.space_bot_id == space_bot.id
      assert post.body == "Hi @bobby"
    end

    test "subscribes the recipient to the post", %{levelbot: space_bot, recipient: recipient} do
      params = valid_post_params() |> Map.merge(%{body: "Hi @bobby"})
      {:ok, %{post: post}} = Posts.create_post(space_bot, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, recipient)
    end

    test "stores the locator", %{levelbot: space_bot, recipient: recipient} do
      locator_params = %{scope: "level", topic: "welcome_message", key: recipient.id}
      params = valid_post_params() |> Map.merge(%{body: "Hi @bobby", locator: locator_params})
      {:ok, %{post: post, locator: locator}} = Posts.create_post(space_bot, params)

      assert locator.post_id == post.id
      assert locator.scope == "level"
      assert locator.topic == "welcome_message"
      assert locator.key == recipient.id
    end

    test "returns errors given invalid params", %{levelbot: space_bot} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, :post, changeset, _} = Posts.create_post(space_bot, params)

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
      {:ok, %{group: group}} = create_group(space_user, %{name: "marketing"})
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

      assert {:ok, %{mentions: %{space_users: [%SpaceUser{id: ^mentioned_id}]}}} =
               Posts.create_reply(space_user, post, params)
    end

    test "adds to tagged groups if the post is public", %{space_user: space_user, post: post} do
      {:ok, %{group: another_group}} = create_group(space_user, %{name: "my-group"})

      params =
        valid_reply_params()
        |> Map.put(:body, "Hello #marketing #my-group")

      {:ok, _} = Posts.create_reply(space_user, post, params)

      post = Repo.preload(post, :groups)
      assert Enum.any?(post.groups, fn group -> group.id == another_group.id end)
    end

    test "does not add to tagged groups if the post is private", %{
      group: group,
      space_user: space_user,
      post: post
    } do
      {:ok, _} = Groups.privatize(group)

      {:ok, %{group: another_group}} = create_group(space_user, %{name: "my-group"})

      params =
        valid_reply_params()
        |> Map.put(:body, "What about #my-group")

      {:ok, _} = Posts.create_reply(space_user, post, params)

      post = Repo.preload(post, :groups)
      refute Enum.any?(post.groups, fn group -> group.id == another_group.id end)
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

      {:ok, %{mentions: %{space_users: [%SpaceUser{id: ^mentioned_id}]}}} =
        Posts.create_reply(space_user, post, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, mentioned)

      assert [%Notification{event: "REPLY_CREATED"}] = Notifications.list(mentioned, post)
    end

    test "subscribes channel watchers", %{
      space: space,
      space_user: space_user,
      post: post,
      group: group
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)
      Groups.watch(group, another_user)

      params = valid_reply_params()
      {:ok, _} = Posts.create_reply(space_user, post, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, another_user)
    end

    test "does not loop in mentioned people who previously did not have access", %{
      space: space,
      space_user: space_user,
      post: post,
      group: group
    } do
      {:ok, %{space_user: %SpaceUser{id: mentioned_id} = mentioned}} =
        create_space_member(space, %{handle: "tiff"})

      {:ok, _} = Groups.privatize(group)

      params = valid_post_params() |> Map.merge(%{body: "Hey @tiff"})

      {:ok, %{mentions: %{space_users: [%SpaceUser{id: ^mentioned_id}]}}} =
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

    test "handles channel mentions", %{
      space: space,
      space_user: space_user,
      post: post
    } do
      {:ok, %{group: %Group{id: another_group_id} = another_group}} =
        create_group(space_user, %{name: "devs"})

      {:ok, %{space_user: another_user}} = create_space_member(space)
      Groups.subscribe(another_group, another_user)

      params = valid_reply_params() |> Map.merge(%{body: "Hey @#devs"})

      assert {:ok, %{mentions: %{groups: [%Group{id: ^another_group_id}]}}} =
               Posts.create_reply(space_user, post, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
               Posts.get_user_state(post, another_user)
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
      assert Posts.render_body("@tiff Hey", %{user: viewer}) ==
               {:ok, "<p><span><span class=\"user-mention\">@tiff</span> Hey</span></p>"}

      assert Posts.render_body("@derrick Hey", %{user: viewer}) ==
               {:ok,
                "<p><span><span class=\"user-mention user-mention-current\">@derrick</span> Hey</span></p>"}
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
    test "sets the inbox state to read" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      Notifications.record_post_created(space_user, post)
      assert %{inbox: "EXCLUDED"} = Posts.get_user_state(post, space_user)

      Posts.mark_as_read(space_user, [post])
      assert %{inbox: "READ"} = Posts.get_user_state(post, space_user)
    end
  end

  describe "create_post_reaction/2" do
    test "creates a reaction and handles duplicates" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      {:ok, _} = Posts.create_post_reaction(space_user, post, "👍")

      assert Repo.get_by(PostLog,
               space_user_id: space_user.id,
               post_id: post.id,
               event: "POST_REACTION_CREATED"
             )

      # Duplicate reaction
      space_user_id = space_user.id
      post_id = post.id

      assert {:ok, %PostReaction{space_user_id: ^space_user_id, post_id: ^post_id}} =
               Posts.create_post_reaction(space_user, post, "👍")
    end

    test "records a notification for all subscribers" do
      {:ok, %{space_user: reactor, space: space}} = create_user_and_space()
      {:ok, %{space_user: author}} = create_space_member(space)
      {:ok, %{group: group}} = create_group(reactor)
      {:ok, %{post: post}} = create_post(author, group)

      {:ok, _} = Posts.create_post_reaction(reactor, post, "👍")

      # Does not record a notification for the reactor
      refute Enum.any?(Notifications.list(reactor, post), fn notification ->
               notification.event == "POST_REACTION_CREATED"
             end)

      assert Enum.any?(Notifications.list(author, post), fn notification ->
               notification.event == "POST_REACTION_CREATED"
             end)
    end
  end

  describe "delete_post_reaction/2" do
    test "deletes the reaction if one exists" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, reaction} = Posts.create_post_reaction(space_user, post, "👍")
      {:ok, deleted_reaction} = Posts.delete_post_reaction(space_user, post, "👍")
      assert deleted_reaction.id == reaction.id
    end

    test "returns an error if the user had not reacted" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)

      {:error, "Reaction not found"} = Posts.delete_post_reaction(space_user, post, "👍")
    end
  end

  describe "create_reply_reaction/2" do
    test "creates a reaction and handles duplicates" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, %{reply: reply}} = create_reply(space_user, post)

      refute Posts.reacted?(space_user, reply)

      {:ok, _} = Posts.create_reply_reaction(space_user, post, reply)

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
               Posts.create_reply_reaction(space_user, post, reply)
    end

    test "records a notification for the reply author" do
      {:ok, %{space_user: reactor, space: space}} = create_user_and_space()
      {:ok, %{space_user: author}} = create_space_member(space)
      {:ok, %{group: group}} = create_group(reactor)
      {:ok, %{post: post}} = create_post(reactor, group)
      {:ok, %{reply: reply}} = create_reply(author, post)

      {:ok, _} = Posts.create_reply_reaction(reactor, post, reply)

      # Does not record a notification for the reactor
      refute Enum.any?(Notifications.list(reactor, post), fn notification ->
               notification.event == "REPLY_REACTION_CREATED"
             end)

      assert Enum.any?(Notifications.list(author, post), fn notification ->
               notification.event == "REPLY_REACTION_CREATED"
             end)
    end
  end

  describe "delete_reply_reaction/2" do
    test "deletes the reaction if one exists" do
      {:ok, %{space_user: space_user}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, %{reply: reply}} = create_reply(space_user, post)

      {:ok, reaction} = Posts.create_reply_reaction(space_user, post, reply)

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

  describe "private?/1" do
    test "returns true if a post is a DM" do
      {:ok, %{space_user: author, space: space}} = create_user_and_space()
      {:ok, %{space_user: _}} = create_space_member(space, %{handle: "tiff"})
      {:ok, %{post: post}} = create_global_post(author, %{body: "Hey @tiff"})

      assert {:ok, true} = Posts.private?(post)
    end

    test "returns true if a post belongs to private groups only" do
      {:ok, %{space_user: author}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(author, %{is_private: true})
      {:ok, %{post: post}} = create_post(author, group)

      assert {:ok, true} = Posts.private?(post)
    end

    test "returns false if a post belongs to a public group" do
      {:ok, %{space_user: author}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(author, %{is_private: false})
      {:ok, %{post: post}} = create_post(author, group)

      assert {:ok, false} = Posts.private?(post)
    end
  end

  describe "get_accessor_ids/1" do
    setup do
      {:ok, %{space_user: space_user, space: space}} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{post: post}} = create_post(space_user, group)
      {:ok, %{space_user: space_user, space: space, group: group, post: post}}
    end

    test "excludes users who are not subscribed when post is private", %{
      space: space,
      group: group,
      post: post
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      Groups.privatize(group)

      {:ok, ids} = Posts.get_accessor_ids(post)
      refute Enum.any?(ids, fn id -> id == another_user.id end)
    end

    test "includes users who are subscribed to groups the post is in", %{
      space: space,
      group: group,
      post: post
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      Groups.subscribe(group, another_user)

      {:ok, ids} = Posts.get_accessor_ids(post)
      assert Enum.any?(ids, fn id -> id == another_user.id end)
    end

    test "includes users who are watching groups the post is in", %{
      space: space,
      group: group,
      post: post
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      Groups.watch(group, another_user)

      {:ok, ids} = Posts.get_accessor_ids(post)
      assert Enum.any?(ids, fn id -> id == another_user.id end)
    end

    test "includes users who are not subscribed to groups", %{
      space: space,
      post: post
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      {:ok, ids} = Posts.get_accessor_ids(post)
      assert Enum.any?(ids, fn id -> id == another_user.id end)
    end

    test "includes users who are directly subscribed", %{
      space: space,
      post: post
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      Posts.mark_as_unread(another_user, [post])

      {:ok, ids} = Posts.get_accessor_ids(post)
      assert Enum.any?(ids, fn id -> id == another_user.id end)
    end

    test "includes users who have unsubscribed from a group", %{
      space: space,
      group: group,
      post: post
    } do
      {:ok, %{space_user: another_user}} = create_space_member(space)

      Groups.subscribe(group, another_user)
      Groups.unsubscribe(group, another_user)

      {:ok, ids} = Posts.get_accessor_ids(post)
      assert Enum.any?(ids, fn id -> id == another_user.id end)
    end
  end
end
