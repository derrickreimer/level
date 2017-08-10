defmodule Bridge.Pagination do
  @moduledoc """
  Functions for generating cursor-paginated, GraphQL-friendly query results.
  """

  import Ecto.Query

  alias Bridge.Pagination.Edge
  alias Bridge.Pagination.PageInfo
  alias Bridge.Pagination.Result

  def fetch_result(repo, base_query, args) do
    order_field = args.order_by.field
    total_count = repo.one(apply_count(base_query))

    {:ok, nodes, has_previous_page, has_next_page} =
      fetch_nodes(repo, base_query, order_field, args)

    edges = build_edges(nodes, order_field)

    page_info = %PageInfo{
      start_cursor: start_cursor(edges),
      end_cursor: end_cursor(edges),
      has_next_page: has_next_page,
      has_previous_page: has_previous_page
    }

    result = %Result{
      total_count: total_count,
      edges: edges,
      page_info: page_info
    }

    {:ok, result}
  end

  def fetch_nodes(repo, query, order_field, args) do
    nodes = repo.all(
      query
      |> apply_sort(args)
      |> apply_limit(args)
      |> apply_before_cursor(order_field, args)
      |> apply_after_cursor(order_field, args)
    )

    has_previous_page =
      case repo.one(from r in apply_sort(query, args), limit: 1) do
        nil -> false
        node -> List.first(nodes).id != node.id
      end

    has_next_page = length(nodes) > args.first
    {:ok, Enum.take(nodes, args.first), has_previous_page, has_next_page}
  end

  defp build_edges(nodes, order_field) do
    Enum.map nodes, fn node ->
      cursor = Map.get(node, order_field)
      %Edge{node: node, cursor: cursor}
    end
  end

  defp start_cursor([]), do: nil
  defp start_cursor([edge | _]) do
    edge.cursor
  end

  defp end_cursor([]), do: nil
  defp end_cursor(edges) do
    List.last(edges).cursor
  end

  defp apply_count(query) do
    query
    |> select([r], count(r.id))
  end

  defp apply_limit(query, %{first: limit}) do
    from r in query, limit: ^(limit + 1)
  end

  defp apply_sort(query, %{order_by: %{field: field, direction: direction}}) do
    from r in query, order_by: [{^direction, ^field}]
  end

  defp apply_after_cursor(query, _, %{after: cursor}) when is_nil(cursor), do: query
  defp apply_after_cursor(query, order_field, %{after: cursor}) do
    query |> where([r], field(r, ^order_field) > ^cursor)
  end

  defp apply_before_cursor(query, _, %{before: cursor}) when is_nil(cursor), do: query
  defp apply_before_cursor(query, order_field, %{before: cursor}) do
    query |> where([r], field(r, ^order_field) < ^cursor)
  end
end
