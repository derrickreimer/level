defmodule Level.ConnectionsTest do
  use Level.DataCase, async: true

  alias Level.Connections
  alias Level.Groups

  describe "users/3" do
    setup do
      create_user_and_space(%{last_name: "aaa"})
    end

    test "includes a total count", %{space: space, user: user} do
      insert_member(space)
      {:ok, %{total_count: count}} = Connections.users(space, %{first: 10}, build_context(user))
      assert count == 2
    end

    test "includes edges", %{space: space, user: user} do
      insert_member(space, %{last_name: "bbb"})
      {:ok, %{edges: edges}} = Connections.users(space, %{first: 10}, build_context(user))

      nodes = Enum.map(edges, & &1.node)
      cursors = Enum.map(edges, & &1.cursor)

      assert Enum.map(nodes, & &1.last_name) == ["aaa", "bbb"]
      assert cursors == ["aaa", "bbb"]
    end

    test "includes page info", %{space: space, user: user} do
      insert_member(space, %{last_name: "bbb"})
      {:ok, %{page_info: page_info}} = Connections.users(space, %{first: 10}, build_context(user))

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "bbb"
    end

    test "includes previous/next page flags", %{space: space, user: user} do
      insert_member(space, %{last_name: "bbb"})
      {:ok, %{page_info: page_info}} = Connections.users(space, %{first: 1}, build_context(user))

      assert page_info.start_cursor == "aaa"
      assert page_info.end_cursor == "aaa"
      assert page_info.has_next_page
      refute page_info.has_previous_page

      {:ok, %{page_info: page_info2}} =
        Connections.users(space, %{first: 1, after: "aaa"}, build_context(user))

      assert page_info2.start_cursor == "bbb"
      assert page_info2.end_cursor == "bbb"
      refute page_info2.has_next_page
      assert page_info2.has_previous_page
    end
  end

  describe "groups/3" do
    setup do
      create_user_and_space()
    end

    test "includes open groups by default", %{space: space, user: user} do
      {:ok, %{group: open_group}} = create_group(user)
      {:ok, %{edges: edges}} = Connections.groups(space, %{first: 10}, build_context(user))

      assert edges_include?(edges, open_group.id)
    end

    test "does not include closed groups by default", %{space: space, user: user} do
      {:ok, %{group: group}} = create_group(user)
      {:ok, closed_group} = Groups.close_group(group)
      {:ok, %{edges: edges}} = Connections.groups(space, %{first: 10}, build_context(user))

      refute edges_include?(edges, closed_group.id)
    end

    test "filters by closed state", %{space: space, user: user} do
      {:ok, %{group: open_group}} = create_group(user)
      {:ok, %{group: closed_group}} = create_group(user)
      {:ok, closed_group} = Groups.close_group(closed_group)

      {:ok, %{edges: edges}} =
        Connections.groups(space, %{first: 10, state: "CLOSED"}, build_context(user))

      assert edges_include?(edges, closed_group.id)
      refute edges_include?(edges, open_group.id)
    end
  end

  describe "group_memberships/3" do
    setup do
      create_user_and_space()
    end

    test "includes groups the user is a member of", %{user: user} do
      {:ok, %{group: group}} = create_group(user)

      {:ok, %{edges: edges}} =
        Connections.group_memberships(user, %{first: 10}, build_context(user))

      assert Enum.any?(edges, fn edge -> edge.node.group_id == group.id end)
    end

    test "does not include groups the user is not a member of", %{user: user, space: space} do
      {:ok, %{group: group}} = create_group(user)
      {:ok, another_user} = insert_member(space)

      {:ok, %{edges: edges}} =
        Connections.group_memberships(another_user, %{first: 10}, build_context(another_user))

      refute Enum.any?(edges, fn edge -> edge.node.group_id == group.id end)
    end

    test "only exposes memberships for authenticated user", %{user: user, space: space} do
      {:ok, another_user} = insert_member(space)

      assert {:error, "Group memberships are only readable for the authenticated user"} ==
               Connections.group_memberships(user, %{first: 10}, build_context(another_user))
    end
  end

  def edges_include?(edges, node_id) do
    Enum.any?(edges, fn edge -> edge.node.id == node_id end)
  end

  def build_context(user) do
    %{context: %{current_user: user}}
  end
end
