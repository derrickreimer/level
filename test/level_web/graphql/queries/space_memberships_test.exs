defmodule LevelWeb.GraphQL.SpaceMembershipsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    {
      viewer {
        spaceMemberships(first: 10) {
          edges {
            node {
              space {
                name
              }
            }
          }
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, user} = create_user()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "users can list their space memberships", %{conn: conn, user: user} do
    {:ok, %{space: _space}} = create_space(user, %{name: "Level"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", @query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
                 "spaceMemberships" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "space" => %{
                           "name" => "Level"
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
