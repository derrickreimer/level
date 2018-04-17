defmodule Level.PostsTest do
  use Level.DataCase, async: true

  alias Level.Posts

  describe "create_post/2" do
    setup do
      insert_signup()
    end

    test "creates a new post given valid params", %{user: user} do
      params = valid_post_params() |> Map.merge(%{body: "The body"})
      {:ok, post} = Posts.create_post(user, params)
      assert post.user_id == user.id
      assert post.body == "The body"
    end

    test "returns errors given invalid params", %{user: user} do
      params = valid_post_params() |> Map.merge(%{body: nil})
      {:error, changeset} = Posts.create_post(user, params)

      assert %Ecto.Changeset{errors: [body: {"can't be blank", [validation: :required]}]} =
               changeset
    end
  end
end
