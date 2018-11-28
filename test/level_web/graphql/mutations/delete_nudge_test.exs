defmodule LevelWeb.GraphQL.DeleteNudgeTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Nudges

  @query """
    mutation DeleteNudge(
      $space_id: ID!,
      $nudge_id: ID!
    ) {
      deleteNudge(
        spaceId: $space_id,
        nudgeId: $nudge_id
      ) {
        success
        nudge {
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

  test "deletes the nudge", %{conn: conn, space_user: space_user, space: space} do
    {:ok, nudge} = Nudges.create_nudge(space_user, %{minute: 440})

    variables = %{space_id: space.id, nudge_id: nudge.id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "deleteNudge" => %{
                 "success" => true,
                 "nudge" => %{
                   "id" => nudge.id
                 },
                 "errors" => []
               }
             }
           }

    assert {:error, _} = Nudges.get_nudge(space_user, nudge.id)
  end

  test "returns top-level errors if nudge does not exist", %{conn: conn, space: space} do
    variables = %{space_id: space.id, nudge_id: "11111111-1111-1111-1111-111111111111"}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{"deleteNudge" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 5}],
                 "message" => "Nudge not found",
                 "path" => ["deleteNudge"]
               }
             ]
           }
  end
end
