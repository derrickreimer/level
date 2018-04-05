defmodule LevelWeb.GraphQL.ViewerTest do
  use LevelWeb.ConnCase, async: true
  import LevelWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, space: space}} = insert_signup()
    conn = authenticate_with_jwt(conn, space, user)
    {:ok, %{conn: conn, user: user, space: space}}
  end

  test "has fields", %{conn: conn, user: user} do
    query = """
      {
        viewer {
          email
          state
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
                 "email" => user.email,
                 "state" => user.state
               }
             }
           }
  end

  test "has a space connection", %{conn: conn, space: space} do
    query = """
      {
        viewer {
          space {
            name
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
                   "name" => space.name
                 }
               }
             }
           }
  end
end
