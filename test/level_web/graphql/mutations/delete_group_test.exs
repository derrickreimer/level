defmodule LevelWeb.GraphQL.DeleteGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @query """
    mutation DeleteGroup(
      $space_id: ID!,
      $group_id: ID!
    ) {
      deleteGroup(
        spaceId: $space_id,
        groupId: $group_id
      ) {
        success
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

  test "deletes the group if user is an owner", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)

    assert group.state == "OPEN"

    variables = %{space_id: space.id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "deleteGroup" => %{
                 "success" => true,
                 "errors" => []
               }
             }
           }

    assert {:error, _} = Groups.get_group(space_user, group.id)
  end
end
