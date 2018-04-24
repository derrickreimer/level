defmodule LevelWeb.UserControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "GET /signup" do
    test "renders the registration form", %{conn: conn} do
      conn =
        conn
        |> get("/signup")

      body = html_response(conn, 200)
      assert body =~ "Sign up for Level"
    end
  end

  describe "POST /signup" do
    test "creates a new user with valid input", %{conn: conn} do
      params =
        valid_user_params()
        |> Map.put(:first_name, "Derrick")

      conn =
        conn
        |> post("/signup", %{"user" => params})

      user = conn.assigns[:current_user]
      assert redirected_to(conn, 302) =~ "/spaces"
      assert user.first_name == "Derrick"
    end

    test "renders validation errors with bad input", %{conn: conn} do
      params =
        valid_user_params()
        |> Map.put(:email, "invalid")
        |> Map.put(:first_name, "")

      conn =
        conn
        |> post("/signup", %{"user" => params})

      body = html_response(conn, 200)
      assert body =~ "is invalid"
      assert body =~ "can\&#39;t be blank"
    end
  end
end
