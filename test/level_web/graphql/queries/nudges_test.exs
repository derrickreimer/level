defmodule LevelWeb.GraphQL.NudgesTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Nudges
  alias Level.Schemas.Nudge

  @query """
    query GetNudges(
      $space_id: ID!
    ) {
      spaceUser(spaceId: $space_id) {
        nudges {
          id
          minute
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, user} = create_user()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "authenticated space user can read their own nudges", %{conn: conn, user: user} do
    {:ok, %{space: space, space_user: space_user}} = create_space(user)
    {:ok, %Nudge{id: nudge_id}} = Nudges.create_nudge(space_user, %{minute: 660})

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: %{space_id: space.id}})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUser" => %{
                 "nudges" => [
                   %{
                     "id" => nudge_id,
                     "minute" => 660
                   }
                 ]
               }
             }
           }
  end
end
