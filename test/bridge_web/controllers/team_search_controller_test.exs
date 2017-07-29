defmodule BridgeWeb.TeamSearchControllerTest do
  use BridgeWeb.ConnCase

  describe "GET /teams/search" do
    test "includes the correct heading", %{conn: conn} do
      conn =
        conn
        |> put_launch_host()
        |> get("/teams/search")

      assert html_response(conn, 200) =~ "Sign in to Bridge"
    end
  end

  describe "POST /" do
    test "redirects to team login page if team exists", %{conn: conn} do
      {:ok, %{team: team}} = insert_signup()

      conn =
        conn
        |> put_launch_host()
        |> post("/teams/search", %{"search" => %{"slug" => team.slug}})

      assert redirected_to(conn, 302) =~ "/login"
    end

    test "renders an error if team does not exist", %{conn: conn} do
      conn =
        conn
        |> put_launch_host()
        |> post("/teams/search", %{"search" => %{"slug" => "doesnotexist"}})

      assert html_response(conn, 200) =~ "We could not find your team"
    end
  end
end
