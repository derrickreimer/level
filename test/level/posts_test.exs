defmodule Level.PostsTest do
  use Level.DataCase, async: true

  alias Level.Posts

  describe "create_post/2" do
    setup do
      create_user_and_space()
    end

    test "creates a new post given valid params", %{member: member} do
      params = valid_post_params() |> Map.merge(%{body: "The body"})
      {:ok, post} = Posts.create_post(member, params)
      assert post.space_member_id == member.id
      assert post.body == "The body"
    end

    test "returns errors given invalid params", %{member: member} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, changeset} = Posts.create_post(member, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end
  end
end
