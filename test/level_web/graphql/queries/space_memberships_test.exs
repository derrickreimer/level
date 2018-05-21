defmodule LevelWeb.GraphQL.SpaceMembershipsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @single_query """
    query GetMembership(
      $space_id: ID!
    ) {
      spaceUser(spaceId: $space_id) {
        role
        space {
          name
        }
      }
    }
  """

  @list_query """
    {
      viewer {
        spaceUsers(first: 10) {
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

  test "users can lookup a membership by space id", %{conn: conn, user: user} do
    {:ok, %{space: space}} = create_space(user, %{name: "Level"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @single_query, variables: %{space_id: space.id}})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUser" => %{
                 "role" => "OWNER",
                 "space" => %{
                   "name" => "Level"
                 }
               }
             }
           }
  end

  test "users can list their space memberships", %{conn: conn, user: user} do
    {:ok, %{space: _space}} = create_space(user, %{name: "Level"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", @list_query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
                 "spaceUsers" => %{
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
