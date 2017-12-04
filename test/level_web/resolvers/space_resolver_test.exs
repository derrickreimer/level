defmodule LevelWeb.SpaceResolverTest do
  use Level.DataCase, async: false

  alias LevelWeb.SpaceResolver

  describe "users/3" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup(%{username: "aaa"})
      {:ok, %{space: space, owner: user}}
    end

    test "includes a total count", %{space: space} do
      insert_member(space)
      {:ok, %{total_count: count}} = SpaceResolver.users(space, %{first: 10}, %{})
      assert count == 2
    end

    test "includes edges", %{space: space} do
      insert_member(space, %{username: "bbb"})
      {:ok, %{edges: edges}} = SpaceResolver.users(space, %{first: 10}, %{})

      nodes = Enum.map(edges, &(&1.node))
      cursors = Enum.map(edges, &(&1.cursor))

      assert Enum.map(nodes, &(&1.username)) == ["aaa", "bbb"]
      assert cursors == ["aaa", "bbb"]
    end

    test "includes page info", %{space: space} do
      insert_member(space, %{username: "bbb"})
      {:ok, %{page_info: page_info}} = SpaceResolver.users(space, %{first: 10}, %{})

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "bbb"
    end

    test "includes previous/next page flags", %{space: space} do
      insert_member(space, %{username: "bbb"})
      {:ok, %{page_info: page_info}} = SpaceResolver.users(space, %{first: 1}, %{})

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "aaa"
      assert page_info.has_next_page
      refute page_info.has_previous_page

      {:ok, %{page_info: page_info2}} = SpaceResolver.users(space, %{first: 1, after: "aaa"}, %{})

      assert page_info2.start_cursor == "bbb"
      assert page_info2.end_cursor == "bbb"
      refute page_info2.has_next_page
      assert page_info2.has_previous_page
    end
  end
end
