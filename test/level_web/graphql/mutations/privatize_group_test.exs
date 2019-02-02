defmodule LevelWeb.GraphQL.PrivatizeGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation PrivatizeGroup(
      $space_id: ID!,
      $group_id: ID!
    ) {
      privatizeGroup(
        spaceId: $space_id,
        groupId: $group_id,
      ) {
        success
        group {
          isPrivate
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

  test "makes a group private", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    variables = %{space_id: group.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "privatizeGroup" => %{
                 "success" => true,
                 "group" => %{
                   "isPrivate" => true
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns top-level error out if group does not exist", %{conn: conn, space: space} do
    variables = %{space_id: space.id, group_id: Ecto.UUID.generate()}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"privatizeGroup" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 5}],
                 "message" => "Group not found",
                 "path" => ["privatizeGroup"]
               }
             ]
           }
  end
end
