defmodule LevelWeb.GraphQL.PublicizeGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @query """
    mutation PublicizeGroup(
      $space_id: ID!,
      $group_id: ID!
    ) {
      publicizeGroup(
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

  test "makes a group public", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{is_private: true})
    variables = %{space_id: group.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "publicizeGroup" => %{
                 "success" => true,
                 "group" => %{
                   "isPrivate" => false
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns top-level error if user is not allowed", %{
    conn: conn,
    space: space,
    space_user: space_user
  } do
    {:ok, %{space_user: another_member}} = create_space_member(space)
    {:ok, %{group: group}} = create_group(another_member, %{is_private: true})

    # Space user is a non-owner, so cannot change permissions
    Groups.subscribe(group, space_user)

    variables = %{space_id: group.space_id, group_id: group.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"publicizeGroup" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 5}],
                 "message" => "You are not authorized to perform this action.",
                 "path" => ["publicizeGroup"]
               }
             ]
           }
  end

  test "returns top-level error if group does not exist", %{conn: conn, space: space} do
    variables = %{space_id: space.id, group_id: Ecto.UUID.generate()}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"publicizeGroup" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 5}],
                 "message" => "Group not found",
                 "path" => ["publicizeGroup"]
               }
             ]
           }
  end
end
