defmodule Level.SpacesTest do
  use Level.DataCase, async: true
  use Bamboo.Test

  alias Level.Spaces

  describe "get_space_by_slug(!)/1" do
    setup do
      create_user_and_space()
    end

    test "returns the space if found", %{space: space} do
      assert Spaces.get_space_by_slug(space.slug).id == space.id
      assert Spaces.get_space_by_slug!(space.slug).id == space.id
    end

    test "handles when the space is not found" do
      assert Spaces.get_space_by_slug("doesnotexist") == nil

      assert_raise(Ecto.NoResultsError, fn ->
        Spaces.get_space_by_slug!("doesnotexist")
      end)
    end
  end
end
