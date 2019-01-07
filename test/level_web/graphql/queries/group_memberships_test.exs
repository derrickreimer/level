defmodule LevelWeb.GraphQL.GroupMembershipsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups
  alias Level.Spaces

  @query """
    query GetGroupMemberships(
      $group_id: ID!
    ) {
      group(id: $group_id) {
        memberships(first: 10) {
          edges {
            node {
              spaceUser {
                id
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

  test "groups expose their memberships", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

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
                         "spaceUser" => %{
                           "id" => space_user.id
                         }
                       }
                     }
                   ]
                 }
               }
             }
           }
  end

  test "group memberships do not include disabled users", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)

    {:ok, %{space_user: another_user}} = create_space_member(space)

    Groups.subscribe(group, another_user)
    Spaces.revoke_access(another_user)

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
                         "spaceUser" => %{
                           "id" => space_user.id
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
