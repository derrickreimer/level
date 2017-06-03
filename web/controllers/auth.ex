defmodule Bridge.Auth do
  @moduledoc """
  Provides a user authentication plug and other auth-related helper functions.
  """

  import Plug.Conn

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  @doc """
  Looks up the currently logged in user (for the particular Pod that is set
  in the assigns) and assigns it to the current_user key. If pod is not
  specified or user is not logged in, sets the current_user to nil.
  """
  def call(conn, repo) do
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
  Signs a user in to a particular pod.
  """
  def sign_in(conn, pod, user) do
    conn
    |> put_current_user(user)
    |> put_user_session(pod, user)
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
