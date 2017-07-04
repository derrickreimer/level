defmodule Bridge.Web.API.UserTokenControllerTest do
  use Bridge.Web.ConnCase

  describe "POST /api/:team_id/user_tokens" do
    setup %{conn: conn} do
      {:ok, %{team: team, user: user}} = insert_signup()

      conn =
        conn
        |> bypass_through(Bridge.Web.Router, :browser)
        |> get("/")

      {:ok, %{conn: conn, team: team, user: user}}
    end

    test "generates a JWT for signed in user",
      %{conn: conn, team: team, user: user} do

      conn =
        conn
        |> sign_in(team, user)
        |> put_req_header("content-type", "application/json")
        |> post("/api/#{team.slug}/user_tokens")

      %{"token" => token} = json_response(conn, 201)
      decoded_token = Bridge.Web.UserAuth.verify_signed_jwt(token)
      assert decoded_token.claims["sub"] == user.id
    end

    test "responds with unauthorized is user is not signed in",
      %{conn: conn, team: team} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> assign(:current_user, nil)
        |> post("/api/#{team.slug}/user_tokens")

      assert conn.status == 401
    end
  end
end
