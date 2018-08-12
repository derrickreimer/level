defmodule LevelWeb.GraphQL.GroupsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  @edge_query """
    query Groups(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        groups(first: 2) {
          edges {
            node {
              name
              isBookmarked
            }
          }
          total_count
        }
      }
    }
  """

  @closed_query """
    query Groups(
      $space_id: ID!
    ) {
      space(id: $space_id) {
        groups(first: 2, state: CLOSED) {
          edges {
            node {
              name
            }
          }
          total_count
        }
      }
    }
  """

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, space_user: space_user}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, space_user: space_user}}
  end

  test "spaces have a paginated groups field", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @edge_query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "groups" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "name" => group.name,
                         "isBookmarked" => true
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end

  test "filtering groups by state", %{conn: conn, space_user: space_user} do
    {:ok, %{group: _open_group}} = create_group(space_user)
    {:ok, %{group: group}} = create_group(space_user)
    {:ok, closed_group} = Groups.close_group(group)

    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @closed_query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "groups" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "name" => closed_group.name
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end

  test "can represent unbookmarked groups", %{conn: conn, space_user: space_user} do
    {:ok, %{group: group}} = create_group(space_user)
    Groups.unbookmark_group(group, space_user)
    variables = %{space_id: space_user.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: @edge_query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "groups" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "name" => group.name,
                         "isBookmarked" => false
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end
end
