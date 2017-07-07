defmodule Bridge.Web.SessionControllerTest do
  use Bridge.Web.ConnCase

  describe "GET /login" do
    test "includes the correct heading", %{conn: conn} do
      {:ok, %{team: team}} = insert_signup()

      conn =
        conn
        |> put_team_host(team)
        |> get("/login")

      assert html_response(conn, 200) =~ "Sign in to Bridge"
    end

    test "redirects to threads path if already signed in", %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, team: team}} = insert_signup(%{password: password})

      signed_in_conn =
        conn
        |> put_team_host(team)
        |> post("/login", %{"session" => %{"username" => user.username, "password" => password}})

      conn =
        signed_in_conn
        |> recycle()
        |> put_team_host(team)
        |> get("/login")

      assert conn.host == "#{team.slug}.bridge.test"
      assert redirected_to(conn, 302) =~ "/"
    end
  end

  describe "POST /login" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, team: team}} = insert_signup(%{password: password})
      {:ok, %{conn: conn, user: user, team: team, password: password}}
    end

    test "signs in the user by username",
      %{conn: conn, user: user, team: team, password: password} do

      conn =
        conn
        |> put_team_host(team)
        |> post("/login", %{"session" => %{"username" => user.username, "password" => password}})

      assert conn.assigns.current_user.id == user.id
      assert conn.host == "#{team.slug}.bridge.test"
      assert redirected_to(conn, 302) =~ "/"
    end

    test "signs in the user by email",
      %{conn: conn, user: user, team: team, password: password} do

      conn =
        conn
        |> put_team_host(team)
        |> post("/login", %{"session" => %{"username" => user.email, "password" => password}})

      assert conn.assigns.current_user.id == user.id
      assert conn.host == "#{team.slug}.bridge.test"
      assert redirected_to(conn, 302) =~ "/"
    end

    test "renders an error with invalid credentials",
      %{conn: conn, user: user, team: team} do

        conn =
          conn
          |> put_team_host(team)
          |> post("/login", %{"session" => %{"username" => user.email, "password" => "wrong"}})

      assert conn.assigns.current_user == nil
      assert html_response(conn, 200) =~ "Oops, those credentials are not correct"
    end
  end
end
