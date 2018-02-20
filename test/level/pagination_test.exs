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
      sorted_users = Enum.sort_by(members, fn user -> user.id end)
      base_query = from u in User, where: u.space_id == ^space.id
      {:ok, users: sorted_users, base_query: base_query, space: space}
    end

    test "only first param provided", %{users: users, base_query: base_query} do
      args = %{
        first: 2,
        before: nil,
        after: nil,
        order_by: %{
          field: :id,
          direction: :asc
        }
      }

      {:ok, %Result{edges: edges}} = Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.take(users, 2))
    end

    test "first with after cursor provided", %{users: users, base_query: base_query} do
      args = %{
        first: 2,
        before: nil,
        after: Enum.at(users, 0).id,
        order_by: %{
          field: :id,
          direction: :asc
        }
      }

      {:ok, %Result{edges: edges, page_info: _page_info}} =
        Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.slice(users, 1..2))
    end

    test "only last provider", %{users: users, base_query: base_query} do
      args = %{
        last: 2,
        before: nil,
        after: nil,
        order_by: %{
          field: :id,
          direction: :asc
        }
      }

      {:ok, %Result{edges: edges, page_info: _page_info}} =
        Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.slice(users, 2..3))
    end

    test "last with before cursor provided", %{users: users, base_query: base_query} do
      args = %{
        last: 2,
        before: Enum.at(users, 3).id,
        after: nil,
        order_by: %{
          field: :id,
          direction: :asc
        }
      }

      {:ok, %Result{edges: edges, page_info: _page_info}} =
        Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.slice(users, 1..2))
    end

    test "last with before and after cursors provided", %{users: users, base_query: base_query} do
      args = %{
        last: 2,
        after: Enum.at(users, 1).id,
        before: Enum.at(users, 3).id,
        order_by: %{
          field: :id,
          direction: :asc
        }
      }

      {:ok, %Result{edges: edges, page_info: _page_info}} =
        Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.slice(users, 2..2))
    end

    test "descending order", %{users: users, base_query: base_query} do
      args = %{
        first: 2,
        before: nil,
        after: nil,
        order_by: %{
          field: :id,
          direction: :desc
        }
      }

      {:ok, %Result{edges: edges}} = Pagination.fetch_result(Level.Repo, base_query, args)

      assert map_edge_ids(edges) == map_ids(Enum.take(Enum.reverse(users), 2))
    end

    test "fails when order is nil", %{base_query: base_query} do
      args = %{
        first: 2,
        last: nil,
        before: nil,
        after: nil,
        order_by: nil
      }

      {:error, "order_by is required"} = Pagination.fetch_result(Level.Repo, base_query, args)
    end

    test "fails when neither first nor last is non-nil", %{base_query: base_query} do
      args = %{
        first: nil,
        last: nil,
        before: nil,
        after: nil,
        order_by: %{
          field: :id,
          direction: :asc
        }
      }

      {:error, "first or last is required"} =
        Pagination.fetch_result(Level.Repo, base_query, args)
    end

    test "fails when first and last is set", %{base_query: base_query} do
      args = %{
        first: 10,
        last: 10,
        before: nil,
        after: nil,
        order_by: %{
          field: :id,
          direction: :asc
        }
      }

      {:error, "first and last cannot both be set"} =
        Pagination.fetch_result(Level.Repo, base_query, args)
    end
  end

  defp create_members(space, count, list \\ [])
  defp create_members(_space, count, list) when count < 1, do: list

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
