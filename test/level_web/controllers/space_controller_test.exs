defmodule LevelWeb.SpaceControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "GET /" do
    setup %{conn: conn} do
      conn =
        conn
        |> put_launch_host()
        |> bypass_through(LevelWeb.Router, :browser)
        |> get("/")

      {:ok, %{conn: conn}}
    end

    test "redirects to login page if not signed in", %{conn: conn} do
      conn =
        conn
        |> recycle()
        |> put_launch_host()
        |> get("/")

      assert redirected_to(conn, 302) =~ "/login"
    end

    test "renders the list of signed in spaces", %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      conn =
        conn
        |> sign_in(space, user)
        |> put_launch_host()
        |> get("/")

      body = html_response(conn, 200)
      assert body =~ "My Spaces"
      assert body =~ space.name
    end
  end

  describe "GET /spaces/new" do
    test "returns ok status", %{conn: conn} do
      conn =
        conn
        |> put_launch_host()
        |> get("/spaces/new")

      assert html_response(conn, 200)
    end
  end
end
