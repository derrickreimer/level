defmodule LevelWeb.GraphQL.UpdateGroupMembershipTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation UpdateGroupMembership(
      $space_id: ID!,
      $group_id: ID!,
      $state: GroupMembershipState,
    ) {
      updateGroupMembership(
        spaceId: $space_id,
        groupId: $group_id,
        state: $state
      ) {
        success
        membership {
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

  test "updates state if the user is allowed to access the group", %{
    conn: conn,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Old name"})
    variables = %{space_id: group.space_id, group_id: group.id, state: "NOT_SUBSCRIBED"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateGroupMembership" => %{
                 "success" => true,
                 "membership" => %{
                   "state" => "NOT_SUBSCRIBED"
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns top-level errors if user is not allowed to access the group", %{
    conn: conn,
    space: space
  } do
    {:ok, %{space_user: another_space_user}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(another_space_user, %{is_private: true})
    variables = %{space_id: group.space_id, group_id: group.id, state: "SUBSCRIBED"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"updateGroupMembership" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 6}],
                 "message" => "Group not found",
                 "path" => ["updateGroupMembership"]
               }
             ]
           }
  end
end
