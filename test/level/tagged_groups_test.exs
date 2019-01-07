defmodule Level.TaggedGroupsTest do
  use Level.DataCase, async: true

  alias Level.Schemas.SpaceUser
  alias Level.TaggedGroups

  describe "get_tagged_groups/2" do
    test "fetches tagged public groups" do
      {:ok, %{space: space, space_user: space_user}} = create_user_and_space()
      {:ok, %{group: _}} = create_group(space_user, %{name: "misc", is_private: false})
      {:ok, %{group: _}} = create_group(space_user, %{name: "dev", is_private: false})
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      text = "What do you think? #dev #misc"
      results = TaggedGroups.get_tagged_groups(another_space_user, text)

      assert Enum.any?(results, fn result -> result.name == "misc" end)
      assert Enum.any?(results, fn result -> result.name == "dev" end)
    end

    test "excludes inaccessible groups" do
      {:ok, %{space: space, space_user: space_user}} = create_user_and_space()
      {:ok, %{group: _}} = create_group(space_user, %{name: "secret", is_private: true})
      {:ok, %{group: _}} = create_group(space_user, %{name: "dev", is_private: false})
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      text = "What do you think? #dev #secret"
      results = TaggedGroups.get_tagged_groups(another_space_user, text)

      refute Enum.any?(results, fn result -> result.name == "secret" end)
      assert Enum.any?(results, fn result -> result.name == "dev" end)
    end

    test "returns empty if there are no tagged groups in text" do
      text = "What do you think?"
      results = TaggedGroups.get_tagged_groups(%SpaceUser{}, text)
      assert results == []
    end
  end
end
