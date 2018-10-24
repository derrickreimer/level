defmodule LevelWeb.GraphQL.SubscribeToGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @query """
    mutation SubscribeToGroup(
      $space_id: ID!,
      $group_id: ID!
    ) {
      subscribeToGroup(
        spaceId: $space_id,
        groupId: $group_id,
      ) {
        success
        group {
          id
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

  test "subscribes if group is public", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(another_user)
    variables = %{space_id: group.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "subscribeToGroup" => %{
                 "success" => true,
                 "group" => %{
                   "id" => group.id
                 },
                 "errors" => []
               }
             }
           }

    assert Groups.get_user_state(group, space_user) == :subscribed
    assert Groups.get_user_role(group, space_user) == :member
  end

  test "returns top-level errors if user is not allowed to access the group", %{
    conn: conn,
    space: space
  } do
    {:ok, %{space_user: another_space_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(another_space_user, %{is_private: true})
    variables = %{space_id: group.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"subscribeToGroup" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 5}],
                 "message" => "Group not found",
                 "path" => ["subscribeToGroup"]
               }
             ]
           }
  end
end
