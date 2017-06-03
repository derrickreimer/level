defmodule Bridge.AuthTest do
  use Bridge.ConnCase
  alias Bridge.Auth

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Bridge.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "call/2" do
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

  describe "sign_in/3" do
    setup %{conn: conn} do
      pod = %Bridge.Pod{id: 123}
      user = %Bridge.User{id: 456}
      conn = Auth.sign_in(conn, pod, user)

      {:ok, %{conn: conn, pod: pod, user: user}}
    end

    test "sets the current user", %{conn: conn, user: user} do
      assert conn.assigns.current_user == user
    end

    test "sets the user session", %{conn: conn} do
      %{"123" => %{"user_id" => user_id}} =
        conn
        |> get_session(:sessions)
        |> Poison.decode!

      assert user_id == 456
    end
  end

  defp encoded_sessions(pod, user) do
    Poison.encode!(%{Integer.to_string(pod.id) => %{user_id: user.id}})
  end
end
