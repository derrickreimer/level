defmodule LevelWeb.GraphQL.UpdateGroupTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation UpdateGroup(
      $id: ID!,
      $name: String,
      $description: String,
      $isPrivate: Boolean
    ) {
      updateGroup(
        id: $id,
        name: $name,
        description: $description,
        isPrivate: $isPrivate
      ) {
        success
        group {
          name
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "updates a group given valid data", %{conn: conn, user: user} do
    {:ok, %{group: group}} = insert_group(user, %{name: "Old name"})
    variables = %{id: group.id, name: "New name"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateGroup" => %{
                 "success" => true,
                 "group" => %{
                   "name" => variables.name
                 },
                 "errors" => []
               }
             }
           }
  end
end
