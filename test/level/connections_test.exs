defmodule Level.ConnectionsTest do
  use Level.DataCase, async: true

  alias Level.Connections

  describe "users/3" do
    setup do
      insert_signup(%{last_name: "aaa"})
    end

    test "includes a total count", %{space: space} do
      insert_member(space)
      {:ok, %{total_count: count}} = Connections.users(space, %{first: 10}, %{})
      assert count == 2
    end

    test "includes edges", %{space: space} do
      insert_member(space, %{last_name: "bbb"})
      {:ok, %{edges: edges}} = Connections.users(space, %{first: 10}, %{})

      nodes = Enum.map(edges, & &1.node)
      cursors = Enum.map(edges, & &1.cursor)

      assert Enum.map(nodes, & &1.last_name) == ["aaa", "bbb"]
      assert cursors == ["aaa", "bbb"]
    end

    test "includes page info", %{space: space} do
      insert_member(space, %{last_name: "bbb"})
      {:ok, %{page_info: page_info}} = Connections.users(space, %{first: 10}, %{})

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "bbb"
    end

    test "includes previous/next page flags", %{space: space} do
      insert_member(space, %{last_name: "bbb"})
      {:ok, %{page_info: page_info}} = Connections.users(space, %{first: 1}, %{})

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "aaa"
      assert page_info.has_next_page
      refute page_info.has_previous_page

      {:ok, %{page_info: page_info2}} = Connections.users(space, %{first: 1, after: "aaa"}, %{})

      assert page_info2.start_cursor == "bbb"
      assert page_info2.end_cursor == "bbb"
      refute page_info2.has_next_page
      assert page_info2.has_previous_page
    end
  end
end
