defmodule LevelWeb.GraphQL.GroupMembershipsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    {
      viewer {
        groupMemberships(first: 10) {
          edges {
            node {
              group {
                name
              }
            }
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "users can list their group memberships", %{conn: conn, user: user} do
    {:ok, %{group: _group}} = insert_group(user, %{name: "Cool peeps"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", @query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
                 "groupMemberships" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "group" => %{
                           "name" => "Cool peeps"
                         }
                       }
                     }
                   ]
                 }
               }
             }
           }
  end
end
