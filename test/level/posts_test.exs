defmodule Level.PostsTest do
  use Level.DataCase, async: true

  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Posts
  alias Level.Posts.Post

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
      {:ok, %{post: %Post{id: post_id}}} = post_to_group(space_user, group)
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
      {:ok, %{post: %Post{id: post_id}}} = post_to_group(space_user, group)
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
      {:ok, %{post: %Post{id: post_id}}} = post_to_group(space_user, group)
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
      {:ok, %{post: %Post{id: post_id}}} = post_to_group(space_user, group)
      {:ok, %{user: another_user}} = create_space_member(space)

      assert %Post{id: ^post_id} =
               another_user
               |> Posts.posts_base_query()
               |> Repo.get_by(id: post_id)
    end
  end

  describe "post_to_group/2" do
    setup do
      {:ok, %{space_user: space_user} = result} = create_user_and_space()
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, Map.put(result, :group, group)}
    end

    test "creates a new post given valid params", %{space_user: space_user, group: group} do
      params = valid_post_params() |> Map.merge(%{body: "The body"})
      {:ok, %{post: post}} = Posts.post_to_group(space_user, group, params)
      assert post.space_user_id == space_user.id
      assert post.body == "The body"
    end

    test "puts the post in the given group", %{
      space_user: space_user,
      group: %Group{id: group_id} = group
    } do
      params = valid_post_params()
      {:ok, %{post: post}} = Posts.post_to_group(space_user, group, params)

      post =
        post
        |> Repo.preload(:groups)

      assert [%Group{id: ^group_id} | _] = post.groups
    end

    test "returns errors given invalid params", %{space_user: space_user, group: group} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, :post, changeset, _} = Posts.post_to_group(space_user, group, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end
  end
end
