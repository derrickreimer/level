defmodule LevelWeb.PageControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "GET /" do
    test "renders the marketing home if not logged in", %{conn: conn} do
      conn =
        conn
        |> get("/")

      # Check that a sign-in prompt is present on the page
      assert html_response(conn, 200) =~ "Sign In"
    end

    test "redirects to default space if signed in", %{conn: conn} do
      {:ok, %{user: user}} = create_user_and_space(%{}, %{slug: "level"})

      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/")
        |> sign_in(user)
        |> get("/")

      assert redirected_to(conn, 302) =~ "/level"
    end

    test "redirects to new space route if has no teams", %{conn: conn} do
      {:ok, user} = create_user()

      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/")
        |> sign_in(user)
        |> get("/")

      assert redirected_to(conn, 302) =~ "/teams/new"
    end
  end
end
