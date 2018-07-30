defmodule LevelWeb.GraphQL.GroupMembershipsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query GetGroupMemberships(
      $group_id: ID!
    ) {
      group(id: $group_id) {
        memberships(first: 10) {
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
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "users can list their group memberships", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Cool peeps"})

    variables = %{group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "group" => %{
                 "memberships" => %{
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
