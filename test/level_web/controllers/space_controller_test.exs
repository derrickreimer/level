defmodule LevelWeb.SpaceControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "GET /spaces" do
    setup %{conn: conn} do
      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/spaces")

      {:ok, %{conn: conn}}
    end

    test "redirects to login page if not signed in", %{conn: conn} do
      conn =
        conn
        |> recycle()
        |> get("/spaces")

      assert redirected_to(conn, 302) =~ "/login"
    end

    test "renders the list of signed in spaces", %{conn: conn} do
      {:ok, %{user: user}} = create_user_and_space()

      conn =
        conn
        |> sign_in(user)
        |> get("/spaces")

      body = html_response(conn, 200)
      assert body =~ "My Spaces"
    end
  end

  describe "GET /spaces/new" do
    setup %{conn: conn} do
      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/spaces/new")

      {:ok, %{conn: conn}}
    end

    test "redirects to login page if not signed in", %{conn: conn} do
      conn =
        conn
        |> recycle()
        |> get("/spaces/new")

      assert redirected_to(conn, 302) =~ "/login"
    end

    test "returns ok status if logged in", %{conn: conn} do
      {:ok, %{user: user}} = create_user_and_space()

      conn =
        conn
        |> sign_in(user)
        |> get("/spaces/new")

      assert html_response(conn, 200)
    end
  end
end
