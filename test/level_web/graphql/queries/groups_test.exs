defmodule LevelWeb.GraphQL.GroupsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  setup %{conn: conn} do
    {:ok, %{user: user, space: space, member: member}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space, member: member}}
  end

  test "spaces have a paginated groups field", %{conn: conn, member: member} do
    {:ok, %{group: group}} = create_group(member)

    query = """
      query Groups(
        $space_id: ID!
      ) {
        space(id: $space_id) {
          groups(first: 2) {
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

    variables = %{space_id: member.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

    assert json_response(conn, 200) == %{
             "data" => %{
               "space" => %{
                 "groups" => %{
                   "edges" => [
                     %{
                       "node" => %{
                         "name" => group.name
                       }
                     }
                   ],
                   "total_count" => 1
                 }
               }
             }
           }
  end

  test "filtering groups by state", %{conn: conn, member: member} do
    {:ok, %{group: _open_group}} = create_group(member)
    {:ok, %{group: group}} = create_group(member)
    {:ok, closed_group} = Groups.close_group(group)

    query = """
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

    variables = %{space_id: member.space_id}

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", %{query: query, variables: variables})

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
end
