defmodule LevelWeb.GraphQL.CreateNudgeTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CreateNudge(
      $space_id: ID!,
      $minute: Int!
    ) {
      createNudge(
        spaceId: $space_id,
        minute: $minute
      ) {
        success
        nudge {
          minute
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

  test "creates a nudge given valid data", %{conn: conn, space: space} do
    variables = %{space_id: space.id, minute: 800}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createNudge" => %{
                 "success" => true,
                 "nudge" => %{
                   "minute" => 800
                 },
                 "errors" => []
               }
             }
           }
  end

  test "returns validation errors when data is invalid", %{conn: conn, space: space} do
    variables = %{space_id: space.id, minute: 5000}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createNudge" => %{
                 "success" => false,
                 "nudge" => nil,
                 "errors" => [
                   %{"attribute" => "minute", "message" => "is invalid"}
                 ]
               }
             }
           }
  end
end
