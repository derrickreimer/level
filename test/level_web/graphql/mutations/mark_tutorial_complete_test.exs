defmodule LevelWeb.GraphQL.MarkTutorialCompleteTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation MarkTutorialComplete(
      $space_id: ID!,
      $key: String!
    ) {
      markTutorialComplete(
        spaceId: $space_id,
        key: $key
      ) {
        success
        tutorial {
          key
          isComplete
        }
        errors {
          attribute
          message
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} =
      create_user_and_space(%{time_zone: "Etc/UTC"})

    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "updates the tutorial state", %{conn: conn, space_user: space_user} do
    variables = %{space_id: space_user.space_id, key: "foo"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "markTutorialComplete" => %{
                 "success" => true,
                 "tutorial" => %{
                   "key" => "foo",
                   "isComplete" => true
                 },
                 "errors" => []
               }
             }
           }
  end
end
