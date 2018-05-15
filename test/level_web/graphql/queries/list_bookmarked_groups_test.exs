defmodule LevelWeb.GraphQL.ListBookmarkedGroupsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @query """
    query GetBookmarkedGroups(
      $space_id: ID!
    ) {
      spaceMembership(spaceId: $space_id) {
        bookmarkedGroups {
          name
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, user} = create_user()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user}}
  end

  test "space memberships can list bookmarked groups", %{conn: conn, user: user} do
    {:ok, %{space: space, space_user: space_user}} = create_space(user, %{name: "Level"})
    {:ok, %{group: group}} = create_group(space_user, %{name: "Engineering"})
    Groups.bookmark_group(group, space_user)

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @query, variables: %{space_id: space.id}})

    assert json_response(conn, 200) == %{
             "data" => %{
               "spaceMembership" => %{
                 "bookmarkedGroups" => [
                   %{
                     "name" => "Engineering"
                   }
                 ]
               }
             }
           }
  end
end
