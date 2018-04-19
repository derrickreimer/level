defmodule LevelWeb.AuthTest do
  use LevelWeb.ConnCase, async: true
  alias LevelWeb.Auth

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(LevelWeb.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "fetch_current_user_by_session/2" do
    test "sets the current user to nil if there is no session", %{conn: conn} do
      conn = Auth.fetch_current_user_by_session(conn)
      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if user is not found", %{conn: conn} do
      {:ok, %{space: space}} = create_user_and_space()

      conn =
        conn
        |> assign(:space, space)
        |> put_session(:user_id, Ecto.UUID.generate())
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if salt does not match", %{conn: conn} do
      {:ok, %{user: user}} = create_user_and_space()

      conn =
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:salt, "nacl")
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user if logged in and salt matches", %{conn: conn} do
      {:ok, %{user: user}} = create_user_and_space()

      conn =
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:salt, user.session_salt)
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user.id == user.id
    end
  end

  describe "authenticate_with_token/2" do
    test "sets the current user to nil if there is no token", %{conn: conn} do
      conn = Auth.authenticate_with_token(conn)
      assert conn.assigns.current_user == nil
      assert conn.status == 400
      assert conn.halted
    end

    test "sets the current user to nil if token is expired", %{conn: conn} do
      {:ok, %{user: user}} = create_user_and_space()

      token = generate_expired_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user == nil
      assert conn.status == 401
      assert conn.resp_body == "Token expired"
      assert conn.halted
    end

    test "sets the current user if token is valid", %{conn: conn} do
      {:ok, %{user: user}} = create_user_and_space()

      token = Auth.generate_signed_jwt(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user.id == user.id
      assert conn.private.absinthe[:context][:current_user].id == user.id
      refute conn.halted
    end
  end

  describe "sign_in/3" do
    setup %{conn: conn} do
      {:ok, %{space: space, user: user}} = create_user_and_space()

      conn =
        conn
        |> Auth.sign_in(user)

      {:ok, %{conn: conn, space: space, user: user}}
    end

    test "sets the current user", %{conn: conn, user: user} do
      assert conn.assigns.current_user.id == user.id
      assert get_session(conn, :user_id) == user.id
    end
  end

  describe "sign_out/2" do
  end

  describe "sign_in_with_credentials/5" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{space: space, user: user}} = create_user_and_space(%{password: password})
      {:ok, %{conn: conn, space: space, user: user, password: password}}
    end

    test "signs in user with email credentials", %{
      conn: conn,
      user: user,
      password: password
    } do
      {:ok, conn} = Auth.sign_in_with_credentials(conn, user.email, password)

      assert conn.assigns.current_user.id == user.id
    end

    test "returns unauthorized if password does not match", %{
      conn: conn,
      user: user
    } do
      {:error, :unauthorized, _conn} = Auth.sign_in_with_credentials(conn, user.email, "wrongo")
    end

    test "returns 404 if user is not found", %{conn: conn} do
      {:error, :not_found, _conn} = Auth.sign_in_with_credentials(conn, "foo@bar.co", "wrongo")
    end
  end

  describe "generate_signed_jwt/1" do
    setup do
      user = %Level.Spaces.User{id: 999}
      {:ok, %{user: user}}
    end

    test "references the user as the subject", %{user: user} do
      signed_token = Auth.generate_signed_jwt(user)
      verified_token = Auth.verify_signed_jwt(signed_token)
      %Joken.Token{claims: %{"sub" => user_id}} = verified_token
      assert user_id == to_string(user.id)
    end
  end

  describe "verify_signed_jwt/1" do
    setup do
      user = %Level.Spaces.User{id: 999}
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

  defp generate_expired_token(user) do
    past = 1_499_951_920

    user
    |> Auth.generate_jwt()
    |> Joken.with_exp(past + 1)
    |> Joken.with_iat(past)
    |> Joken.with_nbf(past - 1)
    |> Joken.sign()
    |> Joken.get_compact()
  end
end
