defmodule LevelWeb.GraphQL.GroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    query GetGroup(
      $group_id: ID!
    ) {
      group(id: $group_id) {
        name
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "spaces expose their groups", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineers"})

    variables = %{
      group_id: group.id
    }

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "group" => %{
                 "name" => "Engineers"
               }
             }
           }
  end
end
