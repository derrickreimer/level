defmodule LevelWeb.GraphQL.GraphiQLTest do
  use LevelWeb.ConnCase, async: true

  describe "/graphiql authentication rules" do
    setup %{conn: conn} do
      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/graphiql")

      {:ok, %{conn: conn}}
    end

    test "unauthenticated user should not be able to access /graphiql", %{conn: conn} do
      conn = get(conn, "/graphiql")
      assert redirected_to(conn, 302) =~ "/login"
    end

    test "authenticated users can access /graphiql", %{conn: conn} do
      {:ok, user} = create_user()

      conn =
        conn
        |> sign_in(user)
        # we want the page not the api
        |> put_req_header("accept", "text/html")
        |> get("/graphiql")

      assert html_response(conn, 200)
    end
  end
end
