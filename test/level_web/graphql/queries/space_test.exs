defmodule LevelWeb.GraphQL.SpaceTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "has a paginated users connection", %{conn: conn, user: user} do
    query = """
      {
        viewer {
          space {
            users(first:2) {
              edges {
                node {
                  id
                }
              }
              total_count
              page_info {
                hasPreviousPage
              }
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
          "space" => %{
            "users" => %{
              "edges" => [%{
                "node" => %{
                  "id" => to_string(user.id)
                }
              }],
              "total_count" => 1,
              "page_info" => %{
                "hasPreviousPage" => false
              }
            }
          }
        }
      }
    }
  end
end
