defmodule LevelWeb.GraphQL.RoomSubscriptionsTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "returns room subscriptions for the user", %{conn: conn} do
    query = """
      {
        viewer {
          roomSubscriptions(first: 10) {
            edges {
              node {
                room {
                  name
                }
              }
            }
            total_count
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
          "roomSubscriptions" => %{
            "edges" => [%{
              "node" => %{
                "room" => %{
                  "name" => "Everyone"
                }
              }
            }],
            "total_count" => 1
          }
        }
      }
    }
  end
end
