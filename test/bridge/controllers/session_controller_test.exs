defmodule Bridge.SessionControllerTest do
  use Bridge.Web.ConnCase

  describe "GET /:team_id/login" do
    test "includes the correct heading", %{conn: conn} do
      {:ok, %{team: team}} = insert_signup()
      conn = get conn, "/#{team.slug}/login"
      assert html_response(conn, 200) =~ "Sign in to #{team.name}"
    end

    test "redirects to threads path if already signed in", %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, team: team}} = insert_signup(%{password: password})

      signed_in_conn = post conn, "/#{team.slug}/login",
        %{"session" => %{"username" => user.username, "password" => password}}

      conn = get signed_in_conn, "/#{team.slug}/login"
      assert redirected_to(conn, 302) =~ "/#{team.slug}"
    end
  end

  describe "POST /:team_id/login" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, team: team}} = insert_signup(%{password: password})
      {:ok, %{conn: conn, user: user, team: team, password: password}}
    end

    test "signs in the user by username",
      %{conn: conn, user: user, team: team, password: password} do

      conn = post conn, "/#{team.slug}/login",
        %{"session" => %{"username" => user.username, "password" => password}}

      assert conn.assigns.current_user.id == user.id
      assert redirected_to(conn, 302) =~ "/#{team.slug}"
    end

    test "signs in the user by email",
      %{conn: conn, user: user, team: team, password: password} do

      conn = post conn, "/#{team.slug}/login",
        %{"session" => %{"username" => user.email, "password" => password}}

      assert conn.assigns.current_user.id == user.id
      assert redirected_to(conn, 302) =~ "/#{team.slug}"
    end

    test "renders an error with invalid credentials",
      %{conn: conn, user: user, team: team} do

      conn = post conn, "/#{team.slug}/login",
        %{"session" => %{"username" => user.email, "password" => "wrong"}}

      assert conn.assigns.current_user == nil
      assert html_response(conn, 200) =~ "Oops, those credentials are not correct"
    end
  end
end
