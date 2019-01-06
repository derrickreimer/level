defmodule LevelWeb.GraphQL.GroupsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @edge_query """
    query Groups(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        groups(first: 2) {
          edges {
            node {
              name
            }
          }
          total_count
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "spaces have a paginated groups field", %{conn: conn, space_user: space_user} do
    {:ok, %{group: _group}} = create_group(space_user, %{name: "Cool Kids"})
    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @edge_query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "groups" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["name"] == "Cool Kids"
           end)
  end

  test "filtering groups by state", %{conn: conn, space_user: space_user} do
    {:ok, %{group: _open_group}} = create_group(space_user, %{name: "Open Group"})
    {:ok, %{group: group}} = create_group(space_user, %{name: "Closed Group"})
    {:ok, _closed_group} = Groups.close_group(group)

    query = """
      query Groups(
        $space_id: ID!
      ) {
        space(id: $space_id) {
          groups(first: 2, state: CLOSED) {
            edges {
              node {
                name
              }
            }
            total_count
          }
        }
      }
    """

    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    %{
      "data" => %{
        "space" => %{
          "groups" => %{
            "edges" => edges
          }
        }
      }
    } = json_response(conn, 200)

    assert Enum.any?(edges, fn edge ->
             edge["node"]["name"] == "Closed Group"
           end)

    refute Enum.any?(edges, fn edge ->
             edge["node"]["name"] == "Open Group"
           end)
  end
end
