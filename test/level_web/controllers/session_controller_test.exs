defmodule LevelWeb.SessionControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "GET /login" do
    test "includes the correct heading", %{conn: conn} do
      conn =
        conn
        |> get("/login")

      assert html_response(conn, 200) =~ "Sign in to Level"
    end

    test "redirects to spaces path if already signed in", %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user}} = create_user_and_space(%{password: password})

      signed_in_conn =
        conn
        |> post("/login", %{"session" => %{"email" => user.email, "password" => password}})

      conn =
        signed_in_conn
        |> recycle()
        |> get("/login")

      assert redirected_to(conn, 302) =~ "/spaces"
    end
  end

  describe "POST /login" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user}} = create_user_and_space(%{password: password})
      {:ok, %{conn: conn, user: user, password: password}}
    end

    test "signs in the user", %{conn: conn, user: user, password: password} do
      conn =
        conn
        |> post("/login", %{"session" => %{"email" => user.email, "password" => password}})

      assert conn.assigns.current_user.id == user.id
      assert redirected_to(conn, 302) =~ "/"
    end

    test "renders an error with invalid credentials", %{conn: conn, user: user} do
      conn =
        conn
        |> post("/login", %{"session" => %{"email" => user.email, "password" => "wrong"}})

      assert conn.assigns.current_user == nil
      assert html_response(conn, 200) =~ "Oops, those credentials are not correct"
    end
  end

  describe "GET /logout" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user}} = create_user_and_space(%{password: password})
      {:ok, %{conn: conn, user: user, password: password}}
    end

    test "logs the user out", %{conn: conn, user: user, password: password} do
      signed_in_conn =
        conn
        |> post("/login", %{"session" => %{"email" => user.email, "password" => password}})

      signed_out_conn =
        signed_in_conn
        |> recycle()
        |> get("/logout")

      assert signed_out_conn.assigns[:current_user] == nil
      assert redirected_to(signed_out_conn, 302) =~ "/login"
    end
  end
end
