defmodule Bridge.Web.GenericSessionControllerTest do
  use Bridge.Web.ConnCase

  describe "GET /login" do
    test "includes the correct heading", %{conn: conn} do
      conn = get conn, "/login"
      assert html_response(conn, 200) =~ "Sign in to Bridge"
    end
  end

  describe "POST /login" do
    test "redirects to team login page if team exists", %{conn: conn} do
      {:ok, %{team: team}} = insert_signup()
      conn = post conn, "/login", %{"session" => %{"slug" => team.slug}}
      assert redirected_to(conn, 302) =~ "/#{team.slug}/login"
    end

    test "renders an error if team does not exist", %{conn: conn} do
      conn = post conn, "/login", %{"session" => %{"slug" => "doesnotexist"}}
      assert html_response(conn, 200) =~ "We could not find your team"
    end
  end
end
