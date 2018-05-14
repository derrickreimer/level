defmodule LevelWeb.GraphQL.SpaceMembershipsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Spaces

  @list_query """
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

  @check_role_query """
    query CheckRole(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        viewerRole
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
      |> post("/graphql", @list_query)

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

  test "spaces know the viewer's role", %{conn: conn, user: user} do
    {:ok, %{space: space}} = create_space(user, %{name: "Level"})

    conn1 =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @check_role_query, variables: %{space_id: space.id}})

    assert json_response(conn1, 200) == %{
             "data" => %{
               "space" => %{
                 "viewerRole" => "OWNER"
               }
             }
           }

    {:ok, %{space: another_space}} = create_user_and_space()
    Spaces.create_member(user, another_space)

    conn2 =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @check_role_query, variables: %{space_id: another_space.id}})

    assert json_response(conn2, 200) == %{
             "data" => %{
               "space" => %{
                 "viewerRole" => "MEMBER"
               }
             }
           }
  end
end
