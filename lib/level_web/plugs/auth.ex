defmodule LevelWeb.Auth do
  @moduledoc """
  Provides user authentication-related plugs and other helper functions.
  """

  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller
  import Joken

  alias Level.Repo
  alias Level.Users
  alias Level.Users.User
  alias LevelWeb.Router.Helpers

  @doc """
  A plug that looks up the currently logged in user for the current space
  and assigns it to the `current_user` key. If space is not specified or user is
  not logged in, sets the `current_user` to `nil`.
  """
  def fetch_current_user_by_session(conn, _opts \\ []) do
    cond do
      # This is a backdoor that makes auth testing easier
      user = conn.assigns[:current_user] ->
        sign_in(conn, user)

      user_id = get_session(conn, :user_id) ->
        with {:ok, user} <- Users.get_user_by_id(user_id),
             true <- user.session_salt == get_session(conn, :salt) do
          sign_in(conn, user)
        else
          _ ->
            delete_current_user(conn)
        end

      true ->
        delete_current_user(conn)
    end
  end

  @doc """
  A plug that authenticates the current user via the `Authorization` bearer token.

  - If space is not specified, halts and returns a 400 response.
  - If no token is provided, halts and returns a 401 response.
  - If token is expired, halts and returns a 401 response.
  - If token is for a user not belonging to the space in scope, halts and
    returns a 401 response.
  - If token is valid, sets the `current_user` on the connection assigns and the
    absinthe context.
  """
  def authenticate_with_token(conn, _opts \\ []) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        # This is a backdoor that makes auth testing easier
        sign_in(conn, user)

      _ ->
        verify_bearer_token(conn)
    end
  end

  @doc """
  A plug for ensuring that a user is currently logged in.
  """
  def authenticate_user(conn, _opts \\ []) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> redirect(to: Helpers.session_path(conn, :new))
      |> halt()
    end
  end

  @doc """
  Signs a user in.
  """
  def sign_in(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> put_session(:salt, user.session_salt)
  end

  @doc """
  Signs a user out.
  """
  def sign_out(conn) do
    conn
    |> delete_session(:user_id)
  end

  @doc """
  Looks up the user by email address and checks the password.
  If the user is found and password is valid, signs the user in and returns
  an :ok tuple. Otherwise, returns an :error tuple.
  """
  def sign_in_with_credentials(conn, email, given_pass, _opts \\ []) do
    user = Repo.get_by(User, email: email)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, sign_in(conn, user)}

      user ->
        {:error, :unauthorized, conn}

      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  @doc """
  Verifies the signed token and fetches the user record from the database
  if the token is valid. Otherwise, returns an error.

  ## Examples

      get_user_by_token(valid_token)
      => %{:ok, %{user: user}}

      get_user_by_token(expired_token)
      => %{:error, "the error message goes here"}
  """
  def get_user_by_token(token) do
    case verify_signed_jwt(token) do
      %Joken.Token{claims: %{"sub" => user_id}, error: nil} ->
        user = Repo.get(User, user_id)
        {:ok, %{user: user}}

      %Joken.Token{error: error} ->
        {:error, error}
    end
  end

  @doc """
  Generates a JSON Web Token (JWT) for a particular user for use by front end
  clients. Returns a Joken.Token struct. The token is set to expire within 15
  minutes from generation time.

  Use the `generate_signed_jwt/1` function to generate a fully-signed
  token in binary format.
  """
  def generate_jwt(user) do
    %Joken.Token{}
    |> with_json_module(Poison)
    |> with_exp(current_time() + 15 * 60)
    |> with_iat(current_time())
    |> with_nbf(current_time() - 1)
    |> with_sub(to_string(user.id))
    |> with_signer(hs256(jwt_secret()))
  end

  @doc """
  Generates a fully-signed JSON Web Token (JWT) for a particular user for use by
  front end clients.
  """
  def generate_signed_jwt(user) do
    user
    |> generate_jwt
    |> sign
    |> get_compact
  end

  @doc """
  Verifies a signed JSON Web Token (JWT).
  """
  def verify_signed_jwt(signed_token) do
    signed_token
    |> token
    |> with_signer(hs256(jwt_secret()))
    |> with_validation("exp", &(&1 > current_time()), "Token expired")
    |> with_validation("iat", &(&1 <= current_time()))
    |> with_validation("nbf", &(&1 < current_time()))
    |> verify
  end

  @doc """
  Returns the secret key base to use for signing JSON Web Tokens.
  """
  def jwt_secret do
    Application.get_env(:level, LevelWeb.Endpoint)[:secret_key_base]
  end

  defp verify_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case get_user_by_token(token) do
          {:ok, %{user: user}} ->
            put_current_user(conn, user)

          {:error, message} ->
            send_unauthorized(conn, message)
        end

      _ ->
        conn
        |> delete_current_user()
        |> send_resp(400, "")
        |> halt()
    end
  end

  defp send_unauthorized(conn, body) do
    conn
    |> delete_current_user()
    |> send_resp(401, body)
    |> halt()
  end

  defp put_current_user(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_private(:absinthe, %{context: %{current_user: user}})
  end

  defp delete_current_user(conn) do
    assign(conn, :current_user, nil)
  end
end
