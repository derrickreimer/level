defmodule LevelWeb.SpaceSearchControllerTest do
  use LevelWeb.ConnCase

  describe "GET /spaces/search" do
    test "includes the correct heading", %{conn: conn} do
      conn =
        conn
        |> put_launch_host()
        |> get("/spaces/search")

      assert html_response(conn, 200) =~ "Sign in to Level"
    end
  end

  describe "POST /" do
    test "redirects to space login page if space exists", %{conn: conn} do
      {:ok, %{space: space}} = insert_signup()

      conn =
        conn
        |> put_launch_host()
        |> post("/spaces/search", %{"search" => %{"slug" => space.slug}})

      assert redirected_to(conn, 302) =~ "/login"
    end

    test "renders an error if space does not exist", %{conn: conn} do
      conn =
        conn
        |> put_launch_host()
        |> post("/spaces/search", %{"search" => %{"slug" => "doesnotexist"}})

      assert html_response(conn, 200) =~ "We could not find your space"
    end
  end
end
