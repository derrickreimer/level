defmodule NeuronWeb.API.UserTokenControllerTest do
  use NeuronWeb.ConnCase

  describe "POST /api/user_tokens" do
    setup %{conn: conn} do
      {:ok, %{team: team, user: user}} = insert_signup()

      conn =
        conn
        |> bypass_through(NeuronWeb.Router, :browser)
        |> put_launch_host()
        |> get("/")

      {:ok, %{conn: conn, team: team, user: user}}
    end

    test "generates a JWT for signed in user",
      %{conn: conn, team: team, user: user} do

      conn =
        conn
        |> sign_in(team, user)
        |> put_team_host(team)
        |> put_req_header("content-type", "application/json")
        |> post("/api/user_tokens")

      %{"token" => token} = json_response(conn, 201)
      decoded_token = NeuronWeb.Auth.verify_signed_jwt(token)
      assert decoded_token.claims["sub"] == user.id
    end

    test "responds with unauthorized is user is not signed in", %{team: team} do

      conn =
        build_conn()
        |> put_team_host(team)
        |> put_req_header("content-type", "application/json")
        |> assign(:current_user, nil)
        |> post("/api/user_tokens")

      assert conn.status == 401
    end
  end
end
