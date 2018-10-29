defmodule LevelWeb.PasswordResetControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "GET /reset-password" do
    test "includes the correct heading", %{conn: conn} do
      conn =
        conn
        |> get("/reset-password")

      assert html_response(conn, 200) =~ "Reset my password"
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
        |> get("/reset-password")

      assert redirected_to(conn, 302) =~ "/spaces"
    end
  end

  describe "POST /reset-password" do
    test "redirects to a check your email page", %{conn: conn} do
      conn =
        conn
        |> post("/reset-password", %{"password_reset" => %{"email" => "derrick@level.app"}})

      assert html_response(conn, 302) =~ "/reset-password/initiated"
    end
  end

  describe "GET /reset-password/initiated" do
    test "includes the correct copy", %{conn: conn} do
      conn =
        conn
        |> get("/reset-password/initiated")

      assert html_response(conn, 200) =~ "Check your email for instructions"
    end
  end
end
