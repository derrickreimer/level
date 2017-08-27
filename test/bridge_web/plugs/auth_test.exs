defmodule BridgeWeb.AuthTest do
  use BridgeWeb.ConnCase
  alias BridgeWeb.Auth

  setup %{conn: conn} do
    conn =
      conn
      |> put_launch_host()
      |> bypass_through(BridgeWeb.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "fetch_team/2" do
    test "assigns the team to the connection if found", %{conn: conn} do
      {:ok, %{team: team}} = insert_signup()

      team_conn =
        conn
        |> assign(:subdomain, team.slug)
        |> Auth.fetch_team()

      assert team_conn.assigns.team.id == team.id
    end

    test "raise a 404 if team is not found", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> assign(:subdomain, "doesnotexist")
        |> Auth.fetch_team()
      end
    end
  end

  describe "fetch_current_user_by_session/2" do
    test "does not attach a current user when team is not specified",
      %{conn: conn} do

      conn =
        conn
        |> assign(:team, nil)
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if there is no session", %{conn: conn} do
      conn = Auth.fetch_current_user_by_session(conn)
      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if a team is assigned but no sessions",
      %{conn: conn} do

      conn =
        conn
        |> assign(:team, "team")
        |> put_session(:sessions, nil)
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user if logged in", %{conn: conn} do
      {:ok, %{team: team, user: user}} = insert_signup()

      conn =
        conn
        |> assign(:team, team)
        |> put_session(:sessions, to_user_session(team, user))
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user.id == user.id
    end
  end

  describe "authenticate_with_token/2" do
    test "does not attach a current user when team is not specified",
      %{conn: conn} do

      conn =
        conn
        |> assign(:team, nil)
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user == nil
      assert conn.status == 400
      assert conn.halted
    end

    test "sets the current user to nil if there is no token", %{conn: conn} do
      conn = Auth.authenticate_with_token(conn)
      assert conn.assigns.current_user == nil
      assert conn.status == 400
      assert conn.halted
    end

    test "sets the current user to nil if a team is assigned but no token",
      %{conn: conn} do

      conn =
        conn
        |> assign(:team, "team")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user == nil
      assert conn.status == 400
      assert conn.halted
    end

    test "sets the current user if token is expired", %{conn: conn} do
      {:ok, %{team: team, user: user}} = insert_signup()

      token = generate_expired_token(user)

      conn =
        conn
        |> assign(:team, team)
        |> put_req_header("authorization", "Bearer #{token}")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user == nil
      assert conn.status == 401
      assert conn.resp_body == "Token expired"
      assert conn.halted
    end

    test "sets the current user if token is valid", %{conn: conn} do
      {:ok, %{team: team, user: user}} = insert_signup()

      token = Auth.generate_signed_jwt(user)

      conn =
        conn
        |> assign(:team, team)
        |> put_req_header("authorization", "Bearer #{token}")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user.id == user.id
      assert conn.private.absinthe[:context][:current_user].id == user.id
      refute conn.halted
    end
  end

  describe "sign_in/3" do
    setup %{conn: conn} do
      {:ok, %{team: team, user: user}} = insert_signup()

      conn =
        conn
        |> Auth.sign_in(team, user)

      {:ok, %{conn: conn, team: team, user: user}}
    end

    test "sets the current user", %{conn: conn, user: user} do
      assert conn.assigns.current_user.id == user.id
    end

    test "sets the user session", %{conn: conn, team: team, user: user} do
      team_id = Integer.to_string(team.id)

      %{^team_id => [user_id | _]} =
        conn
        |> get_session(:sessions)
        |> Poison.decode!

      assert user_id == user.id
    end
  end

  describe "sign_out/2" do
    test "signs out of the given team only", %{conn: conn} do
      team1 = %Bridge.Teams.Team{id: 1}
      team2 = %Bridge.Teams.Team{id: 2}

      user1 = %Bridge.Teams.User{id: 1}
      user2 = %Bridge.Teams.User{id: 2}

      conn =
        conn
        |> Auth.sign_in(team1, user1)
        |> Auth.sign_in(team2, user2)
        |> Auth.sign_out(team1)

      sessions =
        conn
        |> get_session(:sessions)
        |> Poison.decode!

      refute Map.has_key?(sessions, "1")
      assert Map.has_key?(sessions, "2")
    end
  end

  describe "sign_in_with_credentials/5" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{team: team, user: user}} = insert_signup(%{password: password})
      {:ok, %{conn: conn, team: team, user: user, password: password}}
    end

    test "signs in user with username credentials",
      %{conn: conn, team: team, user: user, password: password} do

      {:ok, conn} =
        Auth.sign_in_with_credentials(conn, team, user.username, password)

      assert conn.assigns.current_user.id == user.id
    end

    test "signs in user with email credentials",
      %{conn: conn, team: team, user: user, password: password} do

      {:ok, conn} =
        Auth.sign_in_with_credentials(conn, team, user.email, password)

      assert conn.assigns.current_user.id == user.id
    end

    test "returns unauthorized if password does not match",
      %{conn: conn, team: team, user: user} do

      {:error, :unauthorized, _conn} =
        Auth.sign_in_with_credentials(conn, team, user.email, "wrongo")
    end

    test "returns unauthorized if user is not found",
      %{conn: conn, team: team} do

      {:error, :not_found, _conn} =
        Auth.sign_in_with_credentials(conn, team, "foo@bar.co", "wrongo")
    end
  end

  describe "generate_signed_jwt/1" do
    setup do
      user = %Bridge.Teams.User{id: 999}
      {:ok, %{user: user}}
    end

    test "references the user as the subject", %{user: user} do
      signed_token = Auth.generate_signed_jwt(user)
      verified_token = Auth.verify_signed_jwt(signed_token)
      %Joken.Token{claims: %{"sub" => user_id}} = verified_token
      assert user_id == user.id
    end
  end

  describe "verify_signed_jwt/1" do
    setup do
      user = %Bridge.Teams.User{id: 999}
      {:ok, %{user: user}}
    end

    test "returns errors if expired", %{user: user} do
      token = generate_expired_token(user)

      verified_token = Auth.verify_signed_jwt(token)
      %Joken.Token{error: error} = verified_token
      assert error == "Token expired"
    end

    test "returns errors if signature is bogus", %{user: user} do
      token = String.slice(Auth.generate_signed_jwt(user), 0..-2)

      verified_token = Auth.verify_signed_jwt(token)
      %Joken.Token{error: error} = verified_token
      assert error == "Invalid signature"
    end

    test "validates if non-expired", %{user: user} do
      token = Auth.generate_signed_jwt(user)

      verified_token = Auth.verify_signed_jwt(token)
      %Joken.Token{error: error, errors: errors} = verified_token
      assert errors == []
      assert error == nil
    end
  end

  describe "signed_in_teams/1" do
    test "returns an empty list if none logged in", %{conn: conn} do
      assert Auth.signed_in_teams(conn) == []
    end

    test "returns a list of signed-in teams", %{conn: conn} do
      {:ok, %{team: team, user: user}} = insert_signup()

      conn =
        conn
        |> sign_in(team, user)
        |> put_launch_host()
        |> get("/")

      [result] = Auth.signed_in_teams(conn)
      assert result.id == team.id
    end
  end

  defp to_user_session(team, user, ts \\ 123) do
    Poison.encode!(%{Integer.to_string(team.id) => [user.id, ts]})
  end

  defp generate_expired_token(user) do
    past = 1_499_951_920

    user
    |> Auth.generate_jwt
    |> Joken.with_exp(past + 1)
    |> Joken.with_iat(past)
    |> Joken.with_nbf(past - 1)
    |> Joken.sign
    |> Joken.get_compact
  end
end
