defmodule LevelWeb.AuthTest do
  use LevelWeb.ConnCase
  alias LevelWeb.Auth

  setup %{conn: conn} do
    conn =
      conn
      |> put_launch_host()
      |> bypass_through(LevelWeb.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "fetch_space/2" do
    test "assigns the space to the connection if found", %{conn: conn} do
      {:ok, %{space: space}} = insert_signup()

      space_conn =
        conn
        |> assign(:subdomain, space.slug)
        |> Auth.fetch_space()

      assert space_conn.assigns.space.id == space.id
    end

    test "raise a 404 if space is not found", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> assign(:subdomain, "doesnotexist")
        |> Auth.fetch_space()
      end
    end
  end

  describe "fetch_current_user_by_session/2" do
    test "does not attach a current user when space is not specified", %{conn: conn} do
      conn =
        conn
        |> assign(:space, nil)
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if there is no session", %{conn: conn} do
      conn = Auth.fetch_current_user_by_session(conn)
      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if a space is assigned but no sessions", %{conn: conn} do
      conn =
        conn
        |> assign(:space, "space")
        |> put_session(:sessions, nil)
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if user is not found", %{conn: conn} do
      {:ok, %{space: space}} = insert_signup()

      conn =
        conn
        |> assign(:space, space)
        |> put_session(
          :sessions,
          to_user_session(space, %Level.Spaces.User{id: 999, session_salt: "nacl"})
        )
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if salt does not match", %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      old_salted_session = to_user_session(space, user)

      user
      |> Ecto.Changeset.change(%{session_salt: "new salt"})
      |> Repo.update()

      conn =
        conn
        |> assign(:space, space)
        |> put_session(:sessions, old_salted_session)
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user == nil
    end

    test "sets the current user if logged in and salt matches", %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      conn =
        conn
        |> assign(:space, space)
        |> put_session(:sessions, to_user_session(space, user))
        |> Auth.fetch_current_user_by_session()

      assert conn.assigns.current_user.id == user.id
    end
  end

  describe "authenticate_with_token/2" do
    test "does not attach a current user when space is not specified", %{conn: conn} do
      conn =
        conn
        |> assign(:space, nil)
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

    test "sets the current user to nil if a space is assigned but no token", %{conn: conn} do
      conn =
        conn
        |> assign(:space, "space")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user == nil
      assert conn.status == 400
      assert conn.halted
    end

    test "sets the current user if token is expired", %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      token = generate_expired_token(user)

      conn =
        conn
        |> assign(:space, space)
        |> put_req_header("authorization", "Bearer #{token}")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user == nil
      assert conn.status == 401
      assert conn.resp_body == "Token expired"
      assert conn.halted
    end

    test "sets the current user if token is valid", %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      token = Auth.generate_signed_jwt(user)

      conn =
        conn
        |> assign(:space, space)
        |> put_req_header("authorization", "Bearer #{token}")
        |> Auth.authenticate_with_token()

      assert conn.assigns.current_user.id == user.id
      assert conn.private.absinthe[:context][:current_user].id == user.id
      refute conn.halted
    end
  end

  describe "sign_in/3" do
    setup %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      conn =
        conn
        |> Auth.sign_in(space, user)

      {:ok, %{conn: conn, space: space, user: user}}
    end

    test "sets the current user", %{conn: conn, user: user} do
      assert conn.assigns.current_user.id == user.id
    end

    test "sets the user session", %{conn: conn, space: space, user: user} do
      space_id = Integer.to_string(space.id)

      %{^space_id => [user_id | _]} =
        conn
        |> get_session(:sessions)
        |> Poison.decode!()

      assert user_id == user.id
    end
  end

  describe "sign_out/2" do
    test "signs out of the given space only", %{conn: conn} do
      space1 = %Level.Spaces.Space{id: 1}
      space2 = %Level.Spaces.Space{id: 2}

      user1 = %Level.Spaces.User{id: 1}
      user2 = %Level.Spaces.User{id: 2}

      conn =
        conn
        |> Auth.sign_in(space1, user1)
        |> Auth.sign_in(space2, user2)
        |> Auth.sign_out(space1)

      sessions =
        conn
        |> get_session(:sessions)
        |> Poison.decode!()

      refute Map.has_key?(sessions, "1")
      assert Map.has_key?(sessions, "2")
    end
  end

  describe "sign_in_with_credentials/5" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{space: space, user: user}} = insert_signup(%{password: password})
      {:ok, %{conn: conn, space: space, user: user, password: password}}
    end

    test "signs in user with email credentials", %{
      conn: conn,
      space: space,
      user: user,
      password: password
    } do
      {:ok, conn} = Auth.sign_in_with_credentials(conn, space, user.email, password)

      assert conn.assigns.current_user.id == user.id
    end

    test "returns unauthorized if password does not match", %{
      conn: conn,
      space: space,
      user: user
    } do
      {:error, :unauthorized, _conn} =
        Auth.sign_in_with_credentials(conn, space, user.email, "wrongo")
    end

    test "returns unauthorized if user is not found", %{conn: conn, space: space} do
      {:error, :not_found, _conn} =
        Auth.sign_in_with_credentials(conn, space, "foo@bar.co", "wrongo")
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

  describe "signed_in_spaces/1" do
    test "returns an empty list if none logged in", %{conn: conn} do
      assert Auth.signed_in_spaces(conn) == []
    end

    test "returns a list of signed-in spaces", %{conn: conn} do
      {:ok, %{space: space, user: user}} = insert_signup()

      conn =
        conn
        |> sign_in(space, user)
        |> put_launch_host()
        |> get("/")

      [result] = Auth.signed_in_spaces(conn)
      assert result.id == space.id
    end
  end

  defp to_user_session(space, user, ts \\ 123) do
    Poison.encode!(%{Integer.to_string(space.id) => [user.id, user.session_salt, ts]})
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
