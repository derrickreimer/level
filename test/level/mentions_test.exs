defmodule Level.MentionsTest do
  use Level.DataCase, async: true

  alias Level.Mentions
  alias Level.Repo
  alias Level.Schemas.Post
  alias Level.Schemas.UserMention

  describe "dismiss_all/2" do
    setup do
      create_user_and_space()
    end

    test "dismisses all mentions for a given post", %{space_user: space_user, space: space} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_user}} = create_space_member(space, %{handle: "tiff"})

      {:ok, %{post: %Post{id: post_id}}} = create_post(space_user, group, %{body: "Hey @tiff"})

      assert %UserMention{post_id: ^post_id} =
               another_user
               |> Mentions.base_query()
               |> Repo.get_by(post_id: post_id)

      {:ok, [%Post{id: ^post_id}]} = Mentions.dismiss_all(another_user, [post_id])

      assert nil ==
               another_user
               |> Mentions.base_query()
               |> Repo.get_by(post_id: post_id)
    end
  end
end
