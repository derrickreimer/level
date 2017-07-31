defmodule Bridge.TeamUserQuery do
  @moduledoc """
  Helpers for querying team users.
  """

  alias Bridge.User
  alias Bridge.Repo
  import Ecto.Query

  @default_args %{
    first: 10,
    after: nil,
    order_by: %{
      field: "USERNAME",
      direction: "ASC"
    }
  }

  @doc """
  Execute a query for users.

  Acceptable arguments include:

  - `first` - the number of rows to return.
  - `after` - the cursor.
  """
  def run(team, args, context) do
    args = Map.merge(@default_args, args)

    cursor_field = order_field_for(args.order_by.field)
    base_query = base_query(team, args, context)
    total_count = Repo.one(apply_count(base_query))

    {:ok, nodes, has_previous_page, has_next_page} = fetch_nodes(base_query, args)

    edges = build_edges(nodes, cursor_field)

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

  def base_query(team, _args, _context) do
    from u in User, where: u.team_id == ^team.id and u.state == "ACTIVE"
  end

  def fetch_nodes(query, args) do
    nodes = Repo.all(
      query
      |> apply_sort(args)
      |> apply_limit(args)
      |> apply_cursor(args)
    )

    has_previous_page =
      case Repo.one(from u in apply_sort(query, args), limit: 1) do
        nil -> false
        node -> List.first(nodes).id != node.id
      end

    has_next_page = length(nodes) > args.first
    {:ok, Enum.take(nodes, args.first), has_previous_page, has_next_page}
  end

  def build_edges(nodes, cursor_field) do
    Enum.map nodes, fn node ->
      cursor = Map.get(node, cursor_field)
      %{node: node, cursor: cursor}
    end
  end

  def start_cursor(edges) do
    case List.first(edges) do
      nil -> nil
      edge -> edge.cursor
    end
  end

  def end_cursor(edges) do
    case List.last(edges) do
      nil -> nil
      edge -> edge.cursor
    end
  end

  defp apply_count(query) do
    query
    |> select([u], count(u.id))
  end

  defp apply_limit(query, %{first: limit}) do
    from u in query, limit: ^(limit + 1)
  end

  defp apply_sort(query, %{order_by: %{field: field, direction: direction}}) do
    from u in query,
      order_by: [{^direction_for(direction), ^order_field_for(field)}]
  end

  # TODO: Genericize this to handle cursoring by order_by field
  defp apply_cursor(query, %{after: cursor}) when is_nil(cursor), do: query
  defp apply_cursor(query, %{after: cursor}) do
    query
    |> where([u], u.username > ^cursor)
  end

  defp order_field_for("USERNAME"),  do: :username
  defp direction_for("ASC"), do: :asc
  defp direction_for("DESC"), do: :desc
end
