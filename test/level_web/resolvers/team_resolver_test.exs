defmodule LevelWeb.TeamResolverTest do
  use Level.DataCase, async: false

  alias LevelWeb.TeamResolver

  describe "users/3" do
    setup do
      {:ok, %{team: team, user: user}} = insert_signup(%{username: "aaa"})
      {:ok, %{team: team, owner: user}}
    end

    test "includes a total count", %{team: team} do
      insert_member(team)
      {:ok, %{total_count: count}} = TeamResolver.users(team, %{}, %{})
      assert count == 2
    end

    test "includes edges", %{team: team} do
      insert_member(team, %{username: "bbb"})
      {:ok, %{edges: edges}} = TeamResolver.users(team, %{}, %{})

      nodes = Enum.map(edges, &(&1.node))
      cursors = Enum.map(edges, &(&1.cursor))

      assert Enum.map(nodes, &(&1.username)) == ["aaa", "bbb"]
      assert cursors == ["aaa", "bbb"]
    end

    test "includes page info", %{team: team} do
      insert_member(team, %{username: "bbb"})
      {:ok, %{page_info: page_info}} = TeamResolver.users(team, %{}, %{})

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "bbb"
    end

    test "includes previous/next page flags", %{team: team} do
      insert_member(team, %{username: "bbb"})
      {:ok, %{page_info: page_info}} = TeamResolver.users(team, %{first: 1}, %{})

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "aaa"
      assert page_info.has_next_page
      refute page_info.has_previous_page

      {:ok, %{page_info: page_info2}} = TeamResolver.users(team, %{first: 1, after: "aaa"}, %{})

      assert page_info2.start_cursor == "bbb"
      assert page_info2.end_cursor == "bbb"
      refute page_info2.has_next_page
      assert page_info2.has_previous_page
    end
  end
end
