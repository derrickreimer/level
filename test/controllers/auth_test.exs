defmodule Bridge.AuthTest do
  use Bridge.ConnCase
  alias Bridge.Auth

  describe "call/2" do
    setup %{conn: conn} do
      conn =
        conn
        |> bypass_through(Bridge.Router, :browser)
        |> get("/")

      {:ok, %{conn: conn}}
    end

    test "does not attach a current user when pod is not specified",
      %{conn: conn} do

      conn =
        conn
        |> assign(:pod, nil)
        |> Auth.call(Repo)

      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if there is no session", %{conn: conn} do
      conn = Auth.call(conn, Repo)
      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if a pod is assigned but no sessions",
      %{conn: conn} do

      conn =
        conn
        |> assign(:pod, "pod")
        |> put_session(:sessions, nil)
        |> Auth.call(Repo)

      assert conn.assigns.current_user == nil
    end

    test "sets the current user if logged in", %{conn: conn} do
      {:ok, %{pod: pod, user: user}} = insert_signup()

      conn =
        conn
        |> assign(:pod, pod)
        |> put_session(:sessions, encoded_sessions(pod, user))
        |> Auth.call(Repo)

      assert conn.assigns.current_user.id == user.id
    end
  end

  defp encoded_sessions(pod, user) do
    Poison.encode!(%{Integer.to_string(pod.id) => %{user_id: user.id}})
  end
end
