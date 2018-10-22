defmodule LevelWeb.GraphQL.CreateGroupInvitationsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreateGroupInvitations(
      $space_id: ID!,
      $group_id: ID!,
      $invitee_ids: [ID!]
    ) {
      createGroupInvitations(
        spaceId: $space_id,
        groupId: $group_id,
        inviteeIds: $invitee_ids
      ) {
        success
        invitees {
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

  test "creates group invitations given valid data", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, %{space_user: another_user}} = create_space_member(space)

    variables = %{
      space_id: space.id,
      group_id: group.id,
      invitee_ids: [another_user.id]
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createGroupInvitations" => %{
                 "success" => true,
                 "invitees" => [
                   %{
                     "id" => another_user.id
                   }
                 ],
                 "errors" => []
               }
             }
           }
  end
end
