defmodule Level.PostsTest do
  use Level.DataCase, async: true

  alias Level.Posts

  describe "post_to_group/2" do
    setup do
      create_user_and_space()
    end

    test "creates a new post given valid params", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      params = valid_post_params() |> Map.merge(%{body: "The body"})
      {:ok, %{post: post}} = Posts.post_to_group(space_user, group, params)
      assert post.space_user_id == space_user.id
      assert post.body == "The body"
    end

    test "returns errors given invalid params", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, :post, changeset, _} = Posts.post_to_group(space_user, group, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end
  end
end
