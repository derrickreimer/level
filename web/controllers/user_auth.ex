defmodule Bridge.UserAuth do
  @moduledoc """
  Provides user authentication-related plugs and other helper functions.
  """

  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller

  alias Bridge.Router.Helpers

  @doc """
  A plug that looks up the pod in scope and sets it in the connection assigns.
  """
  def fetch_pod(conn, opts) do
    repo = Keyword.fetch!(opts, :repo)
    pod = repo.get_by!(Bridge.Pod, slug: conn.params["pod_id"])
    assign(conn, :pod, pod)
  end

  @doc """
  A plug that looks up the currently logged in user for the current pod
  and assigns it to the current_user key. If pod is not specified or user is
  not logged in, sets the current_user to nil.
  """
  def fetch_current_user(conn, opts) do
    repo = Keyword.fetch!(opts, :repo)

    cond do
      conn.assigns[:pod] == nil ->
        delete_current_user(conn)

      sessions = get_session(conn, :sessions) ->
        pod_id = Integer.to_string(conn.assigns.pod.id)

        case decode_user_sessions(sessions) do
          %{^pod_id => %{"user_id" => user_id}} ->
            user = repo.get(Bridge.User, user_id)
            put_current_user(conn, user)
          _ ->
            delete_current_user(conn)
        end

      true ->
        delete_current_user(conn)
    end
  end

  @doc """
  A plug for ensuring that a user is currently logged in to the particular pod.
  """
  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> redirect(to: Helpers.session_path(conn, :new, conn.assigns.pod))
      |> halt()
    end
  end

  @doc """
  Signs a user in to a particular pod.
  """
  def sign_in(conn, pod, user) do
    conn
    |> put_current_user(user)
    |> put_user_session(pod, user)
  end

  @doc """
  Signs a user out of a particular pod.
  """
  def sign_out(conn, pod) do
    conn
    |> delete_user_session(pod)
  end

  @doc """
  Looks up the user for a given pod by identifier (either username or email
  address) and compares the given password with the password hash.
  If the user is found and password is valid, signs the user in and returns
  an :ok tuple. Otherwise, returns an :error tuple.
  """
  def sign_in_with_credentials(conn, pod, identifier, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)

    column = if Regex.match?(~r/@/, identifier) do
      :email
    else
      :username
    end

    conditions = %{pod_id: pod.id} |> Map.put(column, identifier)
    user = repo.get_by(Bridge.User, conditions)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, sign_in(conn, pod, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  defp put_user_session(conn, pod, user) do
    pod_id = Integer.to_string(pod.id)

    sessions =
      conn
      |> get_session(:sessions)
      |> decode_user_sessions()
      |> Map.put(pod_id, %{user_id: user.id})
      |> encode_user_sessions()

    put_session(conn, :sessions, sessions)
  end

  defp delete_user_session(conn, pod) do
    pod_id = Integer.to_string(pod.id)

    sessions =
      conn
      |> get_session(:sessions)
      |> decode_user_sessions()
      |> Map.delete(pod_id)
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
    conn |> assign(:current_user, nil)
  end

  defp put_current_user(conn, user) do
    conn |> assign(:current_user, user)
  end
end
