defmodule LevelWeb.GraphQL.UpdateRoleTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Spaces

  @query """
    mutation UpdateRole(
      $space_id: ID!,
      $space_user_id: ID!,
      $role: SpaceUserRole!,
    ) {
      updateRole(
        spaceId: $space_id,
        spaceUserId: $space_user_id,
        role: $role
      ) {
        success
        spaceUser {
          role
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user} = result} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, Map.put(result, :conn, conn)}
  end

  test "admins can make members admins", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    # Set current user to admin role
    Spaces.update_space_user(space_user, %{role: "ADMIN"})
    {:ok, %{space_user: another_user}} = create_space_member(space)
    variables = %{space_id: space.id, space_user_id: another_user.id, role: "ADMIN"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateRole" => %{
                 "success" => true,
                 "spaceUser" => %{
                   "role" => "ADMIN"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "owners can make others owners", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    # Set current user to owner role
    Spaces.update_space_user(space_user, %{role: "OWNER"})
    {:ok, %{space_user: another_user}} = create_space_member(space)
    variables = %{space_id: space.id, space_user_id: another_user.id, role: "OWNER"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateRole" => %{
                 "success" => true,
                 "spaceUser" => %{
                   "role" => "OWNER"
                 },
                 "errors" => []
               }
             }
           }
  end
end
