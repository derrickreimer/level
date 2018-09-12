defmodule LevelWeb.GraphQL.GetSpaceUserByUserIdTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query GetSpaceUser(
      $space_id: ID!,
      $user_id: ID!
    ) {
      spaceUserByUserId(spaceId: $space_id, userId: $user_id) {
        firstName
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{space: space, user: user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, space: space, user: user}}
  end

  test "users can lookup other users", %{conn: conn, space: space} do
    {:ok, %{space_user: another_user}} = create_space_member(space, %{first_name: "Bob"})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{
        query: @query,
        variables: %{space_id: space.id, user_id: another_user.user_id}
      })

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUserByUserId" => %{
                 "firstName" => "Bob"
               }
             }
           }
  end
end
