defmodule BridgeWeb.TeamResolver do
  @moduledoc """
  GraphQL query resolution for teams.
  """

  import Ecto.Query
  alias Bridge.Repo

  def users(team, args, _info) do
    # TODO: validate maximum limit

    limit = args[:first] || 10
    cursor = args[:after] || nil

    base_query = from u in Bridge.User,
      where: u.team_id == ^team.id and u.state == "ACTIVE"

    # TODO: Cache this count? This could get slow...
    total_count = Repo.one(from u in base_query, select: count(u.id))

    edge_query = from u in base_query,
      order_by: [asc: u.username],
      limit: ^limit

    edge_query = if cursor do
      from u in edge_query, where: u.username > ^cursor
    else
      edge_query
    end

    edges = Enum.map(Repo.all(edge_query), fn node ->
      %{node: node, cursor: node.username}
    end)

    start_cursor = case List.first(edges) do
      nil -> nil
      edge -> edge.cursor
    end

    end_cursor = case List.last(edges) do
      nil -> nil
      edge -> edge.cursor
    end

    page_info = %{
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      # has_next_page: has_next_page, # TODO
      # has_previous_page: has_previous_page # TODO
    }

    {:ok, %{
      total_count: total_count,
      edges: edges,
      page_info: page_info
    }}
  end
end
