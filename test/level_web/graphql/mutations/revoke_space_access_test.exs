defmodule LevelWeb.GraphQL.RevokeSpaceAccessTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Spaces

  @query """
    mutation RevokeSpaceAccess(
      $space_id: ID!,
      $space_user_id: ID!
    ) {
      revokeSpaceAccess(
        spaceId: $space_id,
        spaceUserId: $space_user_id
      ) {
        success
        spaceUser {
          state
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "revokes space access if the authenticated user is allowed", %{
    conn: conn,
    space: space
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)

    variables = %{space_id: space.id, space_user_id: another_user.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "revokeSpaceAccess" => %{
                 "success" => true,
                 "spaceUser" => %{
                   "state" => "DISABLED"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns top-level errors if current user is not allowed to revoke access", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    # Make the current user a "member" instead of "owner"
    {:ok, _} = Spaces.update_space_user(space_user, %{role: "MEMBER"})

    {:ok, %{space_user: another_user}} = create_space_member(space)

    variables = %{space_id: space.id, space_user_id: another_user.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"revokeSpaceAccess" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 5}],
                 "message" => "You are not authorized to perform this action.",
                 "path" => ["revokeSpaceAccess"]
               }
             ]
           }
  end
end
