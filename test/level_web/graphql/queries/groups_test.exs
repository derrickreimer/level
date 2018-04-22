defmodule LevelWeb.GraphQL.GroupsTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  alias Level.Groups

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = create_user_and_space()
    conn = authenticate_with_jwt(conn, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "spaces have a paginated groups field", %{conn: conn, user: user} do
    {:ok, %{group: group}} = insert_group(user)

    query = """
      {
        viewer {
          space {
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
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
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
           }
  end

  test "filtering groups by state", %{conn: conn, user: user} do
    {:ok, %{group: _open_group}} = insert_group(user)
    {:ok, %{group: group}} = insert_group(user)
    {:ok, closed_group} = Groups.close_group(group)

    query = """
      {
        viewer {
          space {
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
      }
    """

    conn =
      conn
      |> put_graphql_headers()
      |> post("/graphql", query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "viewer" => %{
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
           }
  end
end
