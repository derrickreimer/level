defmodule Level.MentionsTest do
  use Level.DataCase, async: true

  alias Level.Mentions
  alias Level.Mentions.UserMention
  alias Level.Posts.Post
  alias Level.Repo

  describe "grouped_base_query/1" do
    setup do
      create_user_and_space()
    end

    test "returns grouped user mentions", %{space_user: space_user, space: space} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "tiff"})
      {:ok, %{post: post}} = create_post(space_user, group, %{body: "Hey @tiff"})

      [mention] =
        another_user
        |> Mentions.grouped_base_query()
        |> Repo.all()

      [mentioner] = mention.mentioner_ids
      assert mention.post_id == post.id
      assert Ecto.UUID.load(mentioner) == {:ok, space_user.id}
    end
  end

  describe "dismiss_all/2" do
    setup do
      create_user_and_space()
    end

    test "dismisses all mentions for a given post", %{space_user: space_user, space: space} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "tiff"})

      {:ok, %{post: %Post{id: post_id} = post}} =
        create_post(space_user, group, %{body: "Hey @tiff"})

      assert %UserMention{post_id: ^post_id} =
               another_user
               |> Mentions.base_query()
               |> Repo.get_by(post_id: post_id)

      :ok = Mentions.dismiss_all(another_user, post)

      assert nil ==
               another_user
               |> Mentions.base_query()
               |> Repo.get_by(post_id: post_id)
    end
  end
end
