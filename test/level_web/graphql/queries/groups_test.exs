defmodule LevelWeb.GraphQL.GroupsTest do
  use LevelWeb.ConnCase
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "spaces have a paginated groups field", %{conn: conn, user: user} do
    {:ok, group} = insert_group(user)

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
    insert_group(user)
    {:ok, closed_group} = insert_group(user)

    {:ok, closed_group} =
      closed_group
      |> Ecto.Changeset.change(state: "CLOSED")
      |> Repo.update()

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
