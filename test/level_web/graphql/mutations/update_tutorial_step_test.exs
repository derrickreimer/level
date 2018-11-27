defmodule LevelWeb.GraphQL.UpdateTutorialStepTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation UpdateTutorialStep(
      $space_id: ID!,
      $key: String!,
      $current_step: Int!
    ) {
      updateTutorialStep(
        spaceId: $space_id,
        key: $key,
        currentStep: $current_step
      ) {
        success
        tutorial {
          key
          currentStep
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

  test "updates the tutorial step", %{conn: conn, space_user: space_user} do
    variables = %{space_id: space_user.space_id, key: "foo", current_step: 3}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "updateTutorialStep" => %{
                 "success" => true,
                 "tutorial" => %{
                   "key" => "foo",
                   "currentStep" => 3
                 },
                 "errors" => []
               }
             }
           }
  end
end
