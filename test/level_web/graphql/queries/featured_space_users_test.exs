defmodule LevelWeb.GraphQL.FeaturedSpaceUsersTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query ListFeaturedUsers(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        featuredUsers {
          firstName
          lastName
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "spaces have featured members", %{conn: conn, user: user, space_user: space_user} do
    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "featuredUsers" => [
                   %{
                     "firstName" => user.first_name,
                     "lastName" => user.last_name
                   }
                 ]
               }
             }
           }
  end
end
