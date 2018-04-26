defmodule Level.SpacesTest do
  use Level.DataCase, async: true
  use Bamboo.Test

  alias Level.Spaces

  describe "get_space_by_slug/2" do
    setup do
      create_user_and_space()
    end

    test "returns the space if the user can access it", %{user: user, space: space} do
      {:ok, %{space: found_space, space_user: space_user}} =
        Spaces.get_space_by_slug(user, space.slug)

      assert found_space.id == space.id
      assert space_user.space_id == space.id
      assert space_user.user_id == user.id
    end

    test "returns an error if user cannot access the space", %{space: space} do
      {:ok, another_user} = create_user()

      {:error, message} = Spaces.get_space_by_slug(another_user, space.slug)
      assert message == "Space not found"
    end

    test "returns an error if the space does not exist", %{user: user} do
      {:error, message} = Spaces.get_space_by_slug(user, "idontexist")
      assert message == "Space not found"
    end
  end
end
