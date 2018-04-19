defmodule LevelWeb.API.UserTokenControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "POST /api/tokens" do
    setup %{conn: conn} do
      {:ok, %{space: space, user: user}} = create_user_and_space()

      conn =
        conn
        |> bypass_through(LevelWeb.Router, :browser)
        |> get("/")

      {:ok, %{conn: conn, space: space, user: user}}
    end

    test "generates a JWT for signed in user", %{conn: conn, user: user} do
      conn =
        conn
        |> sign_in(user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/tokens")

      %{"token" => token} = json_response(conn, 201)
      decoded_token = LevelWeb.Auth.verify_signed_jwt(token)
      assert decoded_token.claims["sub"] == to_string(user.id)
    end

    test "responds with unauthorized is user is not signed in", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> assign(:current_user, nil)
        |> post("/api/tokens")

      assert conn.status == 401
    end
  end
end
