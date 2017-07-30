defmodule BridgeWeb.GraphQL.TeamTest do
  use BridgeWeb.ConnCase
  import BridgeWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "has a paginated users connection", %{conn: conn, user: user} do
    query = """
      {
        viewer {
          team {
            users(first:2) {
              edges {
                node {
                  id
                }
              }
              total_count
            }
          }
        }
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
      "data" => %{
        "viewer" => %{
          "team" => %{
            "users" => %{
              "edges" => [%{
                "node" => %{
                  "id" => to_string(user.id)
                }
              }],
              "total_count" => 1
            }
          }
        }
      }
    }
  end
end
