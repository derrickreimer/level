defmodule NeuronWeb.GraphQL.ViewerTest do
  use NeuronWeb.ConnCase
  import NeuronWeb.GraphQL.TestHelpers

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
          recipient_id
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
          "username" => user.username,
          "recipient_id" => "u:#{user.id}",
          "state" => user.state
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
