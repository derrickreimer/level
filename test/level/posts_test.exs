defmodule Level.PostsTest do
  use Level.DataCase, async: true

  import Ecto.Query

  alias Level.File
  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Posts
  alias Level.Posts.Post
  alias Level.Posts.PostView
  alias Level.Posts.Reply
  alias Level.PostVersion
  alias Level.Repo
  alias Level.Spaces.SpaceUser
  alias Level.Users.User

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

    test "should not include posts not in private groups the user cannot access", %{
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

    test "should include posts not in private groups the user can access", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, group} = Groups.update_group(group, %{is_private: true})
      {:ok, %{post: %Post{id: post_id}}} = create_post(space_user, group)
      {:ok, %{user: another_user, space_user: another_space_user}} = create_space_member(space)
      {:ok, _} = Groups.create_group_membership(group, another_space_user)

      assert %Post{id: ^post_id} =
               another_user
               |> Posts.posts_base_query()
               |> Repo.get_by(id: post_id)
    end

    test "should include posts not in public groups", %{
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

  describe "create_post/2" do
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
      assert log.actor_id == space_user.id
      assert log.group_id == group.id
      assert log.post_id == post.id
    end

    test "subscribes mentioned users and marks as unread", %{
      space: space,
      space_user: space_user,
      group: group
    } do
      {:ok, %{space_user: %SpaceUser{id: mentioned_id} = mentioned}} =
        create_space_member(space, %{handle: "tiff"})

      params = valid_post_params() |> Map.merge(%{body: "Hey @tiff"})

      {:ok, %{post: post, mentions: [%SpaceUser{id: ^mentioned_id}]}} =
        Posts.create_post(space_user, group, params)

      assert %{inbox: "UNREAD", subscription: "SUBSCRIBED"} =
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

    test "returns errors given invalid params", %{space_user: space_user, group: group} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, :post, changeset, _} = Posts.create_post(space_user, group, params)

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
      assert log.actor_id == space_user.id
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
      assert log.actor_id == space_user.id
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
    end

    test "marks as unread for subscribers", %{space: space, space_user: space_user, post: post} do
      {:ok, %{space_user: another_subscriber}} = create_space_member(space)
      Posts.subscribe(another_subscriber, [post])
      {:ok, _} = Posts.create_reply(space_user, post, valid_reply_params())
      assert %{inbox: "UNREAD"} = Posts.get_user_state(post, another_subscriber)
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
      assert Posts.render_body("Foo", viewer) == {:ok, "<p>Foo</p>\n"}
    end

    test "emboldens mentions", %{viewer: viewer} do
      assert Posts.render_body("@tiff Hey", viewer) ==
               {:ok, "<p><strong class=\"user-mention\">@tiff</strong> Hey</p>\n"}
    end

    test "applies a special class for viewer mentions", %{viewer: viewer} do
      assert Posts.render_body("@derrick Hey", viewer) ==
               {:ok, "<p><strong class=\"user-mention is-viewer\">@derrick</strong> Hey</p>\n"}
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
end
