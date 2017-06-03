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

      session = get_session(conn, :sessions) ->
        pod_id = Integer.to_string(conn.assigns.pod.id)

        case Poison.decode!(session) do
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

  defp delete_current_user(conn) do
    conn |> assign(:current_user, nil)
  end

  defp put_current_user(conn, user) do
    conn |> assign(:current_user, user)
  end
end
