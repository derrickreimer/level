defmodule Bridge.Web.Auth do
  @moduledoc """
  Provides user authentication-related plugs and other helper functions.
  """

  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller
  import Joken

  alias Bridge.Repo
  alias Bridge.Web.Router.Helpers
  alias Bridge.Web.UrlHelpers

  @doc """
  A plug that looks up the team in scope and sets it in the connection assigns.
  """
  def fetch_team(conn, _opts \\ []) do
    case conn.assigns[:subdomain] do
      "" ->
        conn
        |> redirect(external: UrlHelpers.team_search_url(conn))
        |> halt()

      subdomain ->
        team = Repo.get_by!(Bridge.Team, slug: subdomain)
        assign(conn, :team, team)
    end
  end

  @doc """
  A plug that looks up the currently logged in user for the current team
  and assigns it to the `current_user` key. If team is not specified or user is
  not logged in, sets the `current_user` to `nil`.
  """
  def fetch_current_user_by_session(conn, _opts \\ []) do
    cond do
      conn.assigns[:team] == nil ->
        delete_current_user(conn)

      # This is a backdoor that makes auth testing easier
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      sessions = get_session(conn, :sessions) ->
        team_id = Integer.to_string(conn.assigns.team.id)

        case decode_user_sessions(sessions) do
          %{^team_id => [user_id, _issued_at_ts]} ->
            user = Repo.get(Bridge.User, user_id)
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

  - If team is not specified, halts and returns a 400 response.
  - If no token is provided, halts and returns a 403 response.
  - If token is expired, halts and returns a 403 response.
  - If token is for a user not belonging to the team in scope, halts and
    returns a 403 response.
  - If token is valid, sets the `current_user` on the connection assigns and the
    absinthe context.
  """
  def authenticate_with_token(conn, _opts \\ []) do
    cond do
      conn.assigns[:team] == nil ->
        conn
        |> delete_current_user()
        |> send_resp(400, "")
        |> halt()

      # This is a backdoor that makes auth testing easier
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      true ->
        case get_req_header(conn, "authorization") do
          ["Bearer " <> token] ->
            case verify_signed_jwt(token) do
              %Joken.Token{claims: %{"sub" => user_id}} ->
                user = Repo.get(Bridge.User, user_id)

                if user.team_id == conn.assigns.team.id do
                  put_current_user(conn, user)
                else
                  conn
                  |> delete_current_user()
                  |> send_resp(403, "")
                  |> halt()
                end

              _ ->
                conn
                |> delete_current_user()
                |> send_resp(403, "")
                |> halt()
            end

          _ ->
            conn
            |> delete_current_user()
            |> send_resp(400, "")
            |> halt()
        end
    end
  end

  @doc """
  A plug for ensuring that a user is currently logged in to the particular team.
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
  Signs a user in to a particular team.
  """
  def sign_in(conn, team, user) do
    conn
    |> put_current_user(user)
    |> put_user_session(team, user)
  end

  @doc """
  Signs a user out of a particular team.
  """
  def sign_out(conn, team) do
    conn
    |> delete_user_session(team)
  end

  @doc """
  Looks up the user for a given team by identifier (either username or email
  address) and compares the given password with the password hash.
  If the user is found and password is valid, signs the user in and returns
  an :ok tuple. Otherwise, returns an :error tuple.
  """
  def sign_in_with_credentials(conn, team, identifier, given_pass, _opts \\ []) do
    column = if Regex.match?(~r/@/, identifier) do
      :email
    else
      :username
    end

    conditions = %{team_id: team.id} |> Map.put(column, identifier)
    user = Repo.get_by(Bridge.User, conditions)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, sign_in(conn, team, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  @doc """
  Generates a JSON Web Token (JWT) for a particular user for use by front end
  clients. Returns a Joken.Token struct.

  Use the `generate_signed_jwt/1` function to generate a fully-signed
  token in binary format.
  """
  def generate_jwt(user) do
    token()
    |> Map.put(:claims, %{sub: user.id})
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
    |> verify
  end

  @doc """
  Returns the secret key base to use for signing JSON Web Tokens.
  """
  def jwt_secret do
    Application.get_env(:bridge, Bridge.Web.Endpoint)[:secret_key_base]
  end

  defp put_user_session(conn, team, user) do
    team_id = Integer.to_string(team.id)

    sessions =
      conn
      |> get_session(:sessions)
      |> decode_user_sessions()
      |> Map.put(team_id, [user.id, now_timestamp()])
      |> encode_user_sessions()

    put_session(conn, :sessions, sessions)
  end

  defp delete_user_session(conn, team) do
    team_id = Integer.to_string(team.id)

    sessions =
      conn
      |> get_session(:sessions)
      |> decode_user_sessions()
      |> Map.delete(team_id)
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
