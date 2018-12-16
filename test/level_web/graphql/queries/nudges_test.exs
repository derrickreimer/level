defmodule LevelWeb.GraphQL.NudgesTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Nudges

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
    {:ok, _} = Nudges.create_nudge(space_user, %{minute: 720})

    nudges =
      space_user
      |> Nudges.list_nudges()
      |> Enum.map(fn nudge -> %{"id" => nudge.id, "minute" => nudge.minute} end)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: %{space_id: space.id}})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceUser" => %{
                 "nudges" => nudges
               }
             }
           }
  end
end
