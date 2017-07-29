defmodule BridgeWeb.GraphQL.ViewerTest do
  use BridgeWeb.ConnCase
  import BridgeWeb.GraphQL.TestHelpers

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "has fields", %{conn: conn, user: user} do
    query = """
      {
        viewer {
          username
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
          "username" => user.username
        }
      }
    }
  end

  test "has a team connection", %{conn: conn, team: team} do
    query = """
      {
        viewer {
          team {
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
          "team" => %{
            "name" => team.name
          }
        }
      }
    }
  end
end
