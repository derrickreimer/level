defmodule LevelWeb.GraphQL.CompleteSetupStepTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  @query """
    mutation CompleteSetupStep(
      $space_id: ID!,
      $state: SpaceSetupState!,
      $is_skipped: Boolean!
    ) {
      completeSetupStep(
        spaceId: $space_id,
        state: $state,
        isSkipped: $is_skipped
      ) {
        success
        state
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "marks a setup step as complete", %{conn: conn, space: space} do
    variables = %{space_id: space.id, state: "CREATE_GROUPS", is_skipped: false}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "completeSetupStep" => %{
                 "success" => true,
                 "state" => "INVITE_USERS"
               }
             }
           }
  end
end
