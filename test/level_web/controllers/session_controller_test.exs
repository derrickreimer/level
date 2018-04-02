defmodule LevelWeb.SessionControllerTest do
  use LevelWeb.ConnCase

  describe "GET /login" do
    test "includes the correct heading", %{conn: conn} do
      {:ok, %{space: space}} = insert_signup()

      conn =
        conn
        |> put_space_host(space)
        |> get("/login")

      assert html_response(conn, 200) =~ "Sign in to Level"
    end

    test "redirects to threads path if already signed in", %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, space: space}} = insert_signup(%{password: password})

      signed_in_conn =
        conn
        |> put_space_host(space)
        |> post("/login", %{"session" => %{"email" => user.email, "password" => password}})

      conn =
        signed_in_conn
        |> recycle()
        |> put_space_host(space)
        |> get("/login")

      assert conn.host == "#{space.slug}.level.test"
      assert redirected_to(conn, 302) =~ "/"
    end
  end

  describe "POST /login" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, space: space}} = insert_signup(%{password: password})
      {:ok, %{conn: conn, user: user, space: space, password: password}}
    end

    test "signs in the user", %{conn: conn, user: user, space: space, password: password} do
      conn =
        conn
        |> put_space_host(space)
        |> post("/login", %{"session" => %{"email" => user.email, "password" => password}})

      assert conn.assigns.current_user.id == user.id
      assert conn.host == "#{space.slug}.level.test"
      assert redirected_to(conn, 302) =~ "/"
    end

    test "renders an error with invalid credentials", %{conn: conn, user: user, space: space} do
      conn =
        conn
        |> put_space_host(space)
        |> post("/login", %{"session" => %{"email" => user.email, "password" => "wrong"}})

      assert conn.assigns.current_user == nil
      assert html_response(conn, 200) =~ "Oops, those credentials are not correct"
    end
  end
end
