defmodule Level.Pagination do
  @moduledoc """
  Functions for generating cursor-paginated, GraphQL-friendly query results.
  """

  import Ecto.Query

  alias Level.Pagination.Edge
  alias Level.Pagination.PageInfo
  alias Level.Pagination.Result


  @doc """
  Builds a pagination result that is compatible with GraphQL connections queries.

  ## Examples

      base_query = from u in User,
        where: u.space_id == ^space.id and u.state == "ACTIVE"

      args = %{
        first: 10,
        after: 1000001,
        order_by: %{
          field: :inserted_at,
          direction: :desc
        }
      }

      fetch_result(Level.Repo, base_query, args)
      => {:ok, %Pagination.Result{
        edges: [%User{...}],
        page_info: %PageInfo{...},
        total_count: 10
      }}
  """
  def fetch_result(repo, base_query, args) do
    case validate(args) do
      {:ok, _} ->
        {normalized_args, is_flipped} = normalize(args)

        order_field = normalized_args.order_by.field
        total_count = repo.one(apply_count(base_query))

        {:ok, nodes, has_previous_page, has_next_page} =
          fetch_nodes(repo, base_query, order_field, normalized_args)

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

        {:ok, prepare_result(result, is_flipped)}

      error ->
        error
    end
  end

  defp validate(%{first: nil, last: nil}) do
    {:error, "first or last is required"}
  end
  defp validate(%{first: first, last: last}) when is_integer(first) and is_integer(last) do
    {:error, "first and last cannot both be set"}
  end
  defp validate(%{order_by: nil}) do
    {:error, "order_by is required"}
  end
  defp validate(args) do
    {:ok, args}
  end

  # If we are doing backwards pagination, then flip the sort direction and
  # set `after` to `before` and `first` to `last`. This way we can use all the
  # same logic that transforms the paginated request into `LIMIT` and `OFFSET`
  # in SQL. Returns a tuple of `{args, is_flipped}`.
  defp normalize(%{last: last} = args) when is_nil(last) do
    {args, false}
  end
  defp normalize(%{before: before, last: last, order_by: order_by} = args) do
    flipped_order_by =
      order_by
      |> Map.put(:direction, flip(order_by.direction))

    flipped_args =
      args
      |> Map.put(:before, Map.get(args, :after))
      |> Map.put(:after, before)
      |> Map.put(:first, last)
      |> Map.put(:flipped, true)
      |> Map.put(:order_by, flipped_order_by)

    {flipped_args, true}
  end
  defp normalize(args) do
    {args, false}
  end

  defp flip(direction) do
    case direction do
      :desc -> :asc
      :asc -> :desc
    end
  end

  defp prepare_result(result, false), do: result
  defp prepare_result(%Result{page_info: page_info} = result, _) do
    edges = Enum.reverse(result.edges)

    page_info = %PageInfo{
      start_cursor: page_info.end_cursor,
      end_cursor: page_info.start_cursor,
      has_next_page: page_info.has_previous_page,
      has_previous_page: page_info.has_next_page
    }

    %Result{result | edges: edges, page_info: page_info}
  end

  defp fetch_nodes(repo, query, order_field, args) do
    sorted_query = apply_sort(query, args)

    nodes = repo.all(
      sorted_query
      |> apply_limit(args)
      |> apply_before_cursor(order_field, args)
      |> apply_after_cursor(order_field, args)
    )

    {has_previous_page, has_next_page} =
      case nodes do
        [] -> {false, false}
        _ ->
          has_previous_page =
            case repo.one(from r in sorted_query, limit: 1) do
              nil -> false
              node -> hd(nodes).id != node.id
            end

          has_next_page = length(nodes) > args.first
          {has_previous_page, has_next_page}
      end

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
  defp apply_after_cursor(query, order_field, %{after: cursor, order_by: %{direction: direction}}) do
    case direction do
      :asc ->
        where(query, [r], field(r, ^order_field) > ^cursor)
      :desc ->
        where(query, [r], field(r, ^order_field) < ^cursor)
    end
  end

  defp apply_before_cursor(query, _, %{before: cursor}) when is_nil(cursor), do: query
  defp apply_before_cursor(query, order_field, %{before: cursor, order_by: %{direction: direction}}) do
    case direction do
      :asc ->
        where(query, [r], field(r, ^order_field) < ^cursor)
      :desc ->
        where(query, [r], field(r, ^order_field) > ^cursor)
    end
  end
end
