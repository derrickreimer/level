defmodule Level.PaginationTest do
  use Level.DataCase

  alias Level.Pagination
  alias Level.Spaces.User
  alias Level.Pagination.Result
  import Ecto.Query

  describe "fetch_result/3" do
    setup do
      {:ok, %{user: owner, space: space}} = insert_signup()
      members = [owner | create_members(space, 3)]
      sorted_users = Enum.sort_by(members, fn user -> user.inserted_at end)
      base_query = from u in User, where: u.space_id == ^space.id
      {:ok, users: sorted_users, base_query: base_query}
    end

    test "honors the first param", %{users: users, base_query: base_query} do
      args = %{
        first: 2,
        before: nil,
        after: nil,
        order_by: %{
          field: :inserted_at,
          direction: :asc
        }
      }

      {:ok, %Result{edges: edges}} =
        Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.take(users, 2))
    end

    test "honors the first with cursor", %{users: users, base_query: base_query} do
      args = %{
        first: 2,
        before: nil,
        after: hd(users).inserted_at,
        order_by: %{
          field: :inserted_at,
          direction: :asc
        }
      }

      {:ok, %Result{edges: edges, page_info: page_info}} =
        Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.take(tl(users), 2))
    end
  end

  defp create_members(space, count, list \\ [])
  defp create_members(space, count, list) when count < 1, do: list
  defp create_members(space, count, list) do
    {:ok, user} = insert_member(space)
    create_members(space, count - 1, [user | list])
  end

  defp map_edge_ids(edges) do
    Enum.map(edges, fn edge -> edge.node.id end)
  end

  defp map_ids(nodes) do
    Enum.map(nodes, fn node -> node.id end)
  end
end
