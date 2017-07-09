defmodule Bridge.Web.GraphQLTest do
  use Bridge.Web.ConnCase

  setup %{conn: conn} do
    {:ok, %{user: user, team: team}} = insert_signup()
    conn = authenticate_with_jwt(conn, team, user)
    {:ok, %{conn: conn, user: user, team: team}}
  end

  test "querying viewer properties", %{conn: conn, user: user} do
    query = """
      {
        viewer {
          username
        }
      }
    """

    conn = post_graphql(conn, query)
    assert json_response(conn, 200) == %{
      "data" => %{
        "viewer" => %{
          "username" => user.username
        }
      }
    }
  end

  test "querying viewer team relation", %{conn: conn, team: team} do
    query = """
      {
        viewer {
          team {
            name
          }
        }
      }
    """

    conn = post_graphql(conn, query)
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

  def post_graphql(conn, query) do
    conn
    |> put_req_header("content-type", "application/graphql")
    |> post("/graphql", query)
  end
end
