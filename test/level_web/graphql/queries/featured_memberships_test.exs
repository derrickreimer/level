defmodule LevelWeb.GraphQL.FeaturedMembershipsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query ListFeaturedMemberships(
      $space_id: ID!
      $group_id: ID!
    ) {
      space(id: $space_id) {
        group(id: $group_id) {
          featuredMemberships {
            spaceUser {
              firstName
              lastName
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

  test "groups have featured memberships", %{conn: conn, user: user, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)

    variables = %{space_id: space_user.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "group" => %{
                   "featuredMemberships" => [
                     %{
                       "spaceUser" => %{
                         "firstName" => user.first_name,
                         "lastName" => user.last_name
                       }
                     }
                   ]
                 }
               }
             }
           }
  end
end
