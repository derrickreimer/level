defmodule LevelWeb.Auth do
  @moduledoc """
  Provides user authentication-related plugs and other helper functions.
  """

  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller
  import Joken

  alias Level.Repo
  alias Level.Spaces
  alias LevelWeb.Router.Helpers
  alias LevelWeb.UrlHelpers

  @doc """
  A plug that looks up the space in scope and sets it in the connection assigns.
  """
  def fetch_space(conn, _opts \\ []) do
    case conn.assigns[:subdomain] do
      "" ->
        conn
        |> redirect(external: UrlHelpers.space_search_url(conn))
        |> halt()

      subdomain ->
        space = Spaces.get_space_by_slug!(subdomain)
        assign(conn, :space, space)
    end
  end

  @doc """
  A plug that looks up the currently logged in user for the current space
  and assigns it to the `current_user` key. If space is not specified or user is
  not logged in, sets the `current_user` to `nil`.
  """
  def fetch_current_user_by_session(conn, _opts \\ []) do
    cond do
      conn.assigns[:space] == nil ->
        delete_current_user(conn)

      # This is a backdoor that makes auth testing easier
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      sessions = get_session(conn, :sessions) ->
        space_id = Integer.to_string(conn.assigns.space.id)

        case decode_user_sessions(sessions) do
          %{^space_id => [user_id, _issued_at_ts]} ->
            user = Spaces.get_user(user_id)
            put_current_user(conn, user)
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
    cond do
      conn.assigns[:space] == nil ->
        conn
        |> delete_current_user()
        |> send_resp(400, "")
        |> halt()

      # This is a backdoor that makes auth testing easier
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      true ->
        verify_bearer_token(conn)
    end
  end

  @doc """
  A plug for ensuring that a user is currently logged in to the particular space.
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
  Signs a user in to a particular space.
  """
  def sign_in(conn, space, user) do
    conn
    |> put_current_user(user)
    |> put_user_session(space, user)
  end

  @doc """
  Signs a user out of a particular space.
  """
  def sign_out(conn, space) do
    conn
    |> delete_user_session(space)
  end

  @doc """
  Looks up the user for a given space by identifier (either username or email
  address) and compares the given password with the password hash.
  If the user is found and password is valid, signs the user in and returns
  an :ok tuple. Otherwise, returns an :error tuple.
  """
  def sign_in_with_credentials(conn, space, identifier, given_pass, _opts \\ []) do
    user = Spaces.get_user_by_identifier(space, identifier)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, sign_in(conn, space, user)}
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
        user = Repo.get(Level.Spaces.User, user_id)
        {:ok, %{user: user}}

      %Joken.Token{error: error} ->
        {:error, error}

      _ ->
        {:error, ""}
    end
  end

  @doc """
  Generates a JSON Web Token (JWT) for a particular user for use by front end
  clients. Returns a Joken.Token struct.

  Use the `generate_signed_jwt/1` function to generate a fully-signed
  token in binary format.
  """
  def generate_jwt(user) do
    %Joken.Token{}
    |> with_json_module(Poison)
    |> with_exp(current_time() + (2 * 60 * 60)) # 2 hours from now
    |> with_iat(current_time())
    |> with_nbf(current_time() - 1) # 1 second ago
    |> with_sub(user.id)
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

  @doc """
  Returns a list of spaces currently signed-in via the browser session.
  """
  def signed_in_spaces(conn) do
    import Ecto.Query, only: [from: 2]

    if sessions_json = get_session(conn, :sessions) do
      case decode_user_sessions(sessions_json) do
        nil -> []
        sessions ->
          space_ids = Map.keys(sessions)

          Repo.all(
            from t in Level.Spaces.Space,
              where: t.id in ^space_ids,
              select: t,
              order_by: [asc: t.name]
          )
      end
    else
      []
    end
  end

  defp verify_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case get_user_by_token(token) do
          {:ok, %{user: user}} ->
            if user.space_id == conn.assigns.space.id do
              put_current_user(conn, user)
            else
              send_unauthorized(conn, "")
            end

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

  defp put_user_session(conn, space, user) do
    space_id = Integer.to_string(space.id)

    sessions =
      conn
      |> get_session(:sessions)
      |> decode_user_sessions()
      |> Map.put(space_id, [user.id, now_timestamp()])
      |> encode_user_sessions()

    put_session(conn, :sessions, sessions)
  end

  defp delete_user_session(conn, space) do
    space_id = Integer.to_string(space.id)

    sessions =
      conn
      |> get_session(:sessions)
      |> decode_user_sessions()
      |> Map.delete(space_id)
      |> encode_user_sessions()

    put_session(conn, :sessions, sessions)
  end

  defp decode_user_sessions(data) do
    case data do
      nil -> %{}
      json -> Poison.decode!(json)
    end
  end

  defp encode_user_sessions(data) do
    Poison.encode!(data)
  end

  defp delete_current_user(conn) do
    assign(conn, :current_user, nil)
  end

  defp put_current_user(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_private(:absinthe, %{context: %{current_user: user}})
  end

  defp now_timestamp do
    Timex.to_unix(Timex.now())
  end
end
