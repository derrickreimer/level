defmodule LevelWeb.API.UserTokenControllerTest do
  use LevelWeb.ConnCase

  describe "POST /api/user_tokens" do
    setup %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      conn =
        conn
        |> bypass_through(LevelWeb.Router, :browser)
        |> put_launch_host()
        |> get("/")

      {:ok, %{conn: conn, space: space, user: user}}
    end

    test "generates a JWT for signed in user",
      %{conn: conn, space: space, user: user} do

      conn =
        conn
        |> sign_in(space, user)
        |> put_space_host(space)
        |> put_req_header("content-type", "application/json")
        |> post("/api/user_tokens")

      %{"token" => token} = json_response(conn, 201)
      decoded_token = LevelWeb.Auth.verify_signed_jwt(token)
      assert decoded_token.claims["sub"] == to_string(user.id)
    end

    test "responds with unauthorized is user is not signed in", %{space: space} do
      conn =
        build_conn()
        |> put_space_host(space)
        |> put_req_header("content-type", "application/json")
        |> assign(:current_user, nil)
        |> post("/api/user_tokens")

      assert conn.status == 401
    end
  end
end
