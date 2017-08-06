defmodule Bridge.TeamUserQuery do
  @moduledoc """
  Helpers for querying team users.
  """

  alias Bridge.User
  alias Bridge.Repo
  import Ecto.Query

  @default_args %{
    first: 10,
    before: nil,
    after: nil,
    order_by: %{
      field: "username",
      direction: "asc"
    }
  }

  @doc """
  Execute a query for users.

  Acceptable arguments include:

  - `first`    - the number of rows to return.
  - `after`    - the cursor.
  - `order_by` - the field and direction by which to order the results.
  """
  def run(team, args, _context) do
    base_query = from u in User,
      where: u.team_id == ^team.id and u.state == "ACTIVE"

    fetch_result(base_query, args)
  end

  def parse_args(args) do
    Map.merge(@default_args, args)
  end

  def fetch_result(base_query, args) do
    args = parse_args(args)

    order_field = String.to_atom(args.order_by.field)
    total_count = Repo.one(apply_count(base_query))

    {:ok, nodes, has_previous_page, has_next_page} =
      fetch_nodes(base_query, order_field, args)

    edges = build_edges(nodes, order_field)

    page_info = %{
      start_cursor: start_cursor(edges),
      end_cursor: end_cursor(edges),
      has_next_page: has_next_page,
      has_previous_page: has_previous_page
    }

    payload = %{
      total_count: total_count,
      edges: edges,
      page_info: page_info
    }

    {:ok, payload}
  end

  def fetch_nodes(query, order_field, args) do
    nodes = Repo.all(
      query
      |> apply_sort(args)
      |> apply_limit(args)
      |> apply_before_cursor(order_field, args)
      |> apply_after_cursor(order_field, args)
    )

    has_previous_page =
      case Repo.one(from u in apply_sort(query, args), limit: 1) do
        nil -> false
        node -> List.first(nodes).id != node.id
      end

    has_next_page = length(nodes) > args.first
    {:ok, Enum.take(nodes, args.first), has_previous_page, has_next_page}
  end

  def build_edges(nodes, order_field) do
    Enum.map nodes, fn node ->
      cursor = Map.get(node, order_field)
      %{node: node, cursor: cursor}
    end
  end

  def start_cursor([]), do: nil
  def start_cursor([edge | _]) do
    edge.cursor
  end

  def end_cursor([]), do: nil
  def end_cursor(edges) do
    List.last(edges).cursor
  end

  defp apply_count(query) do
    query
    |> select([u], count(u.id))
  end

  defp apply_limit(query, %{first: limit}) do
    from u in query, limit: ^(limit + 1)
  end

  defp apply_sort(query, %{order_by: %{field: field, direction: direction}}) do
    field = String.to_atom(field)
    direction = String.to_atom(direction)
    from u in query, order_by: [{^direction, ^field}]
  end

  defp apply_after_cursor(query, _, %{after: cursor}) when is_nil(cursor), do: query
  defp apply_after_cursor(query, order_field, %{after: cursor}) do
    query |> where([u], field(u, ^order_field) > ^cursor)
  end

  defp apply_before_cursor(query, _, %{before: cursor}) when is_nil(cursor), do: query
  defp apply_before_cursor(query, order_field, %{before: cursor}) do
    query |> where([u], field(u, ^order_field) < ^cursor)
  end
end
