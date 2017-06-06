defmodule Bridge.UserAuthTest do
  use Bridge.ConnCase
  alias Bridge.UserAuth

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Bridge.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "fetch_pod/2" do
    test "assigns the pod to the connection if found", %{conn: conn} do
      {:ok, %{pod: pod}} = insert_signup()

      pod_conn =
        conn
        |> get("/#{pod.slug}")
        |> UserAuth.fetch_pod(repo: Repo)

      assert pod_conn.assigns.pod.id == pod.id
    end

    test "raise a 404 if pod is not found", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> get("/notfound")
        |> UserAuth.fetch_pod(repo: Repo)
      end
    end
  end

  describe "fetch_current_user/2" do
    test "does not attach a current user when pod is not specified",
      %{conn: conn} do

      conn =
        conn
        |> assign(:pod, nil)
        |> UserAuth.fetch_current_user(repo: Repo)

      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if there is no session", %{conn: conn} do
      conn = UserAuth.fetch_current_user(conn, repo: Repo)
      assert conn.assigns.current_user == nil
    end

    test "sets the current user to nil if a pod is assigned but no sessions",
      %{conn: conn} do

      conn =
        conn
        |> assign(:pod, "pod")
        |> put_session(:sessions, nil)
        |> UserAuth.fetch_current_user(repo: Repo)

      assert conn.assigns.current_user == nil
    end

    test "sets the current user if logged in", %{conn: conn} do
      {:ok, %{pod: pod, user: user}} = insert_signup()

      conn =
        conn
        |> assign(:pod, pod)
        |> put_session(:sessions, to_user_session(pod, user))
        |> UserAuth.fetch_current_user(repo: Repo)

      assert conn.assigns.current_user.id == user.id
    end
  end

  describe "sign_in/3" do
    setup %{conn: conn} do
      {:ok, %{pod: pod, user: user}} = insert_signup()

      login_conn =
        conn
        |> UserAuth.sign_in(pod, user)
        |> send_resp(:ok, "")

      next_conn = get(login_conn, "/#{pod.slug}")

      {:ok, %{conn: next_conn, pod: pod, user: user}}
    end

    test "sets the current user when viewing a page in the pod",
      %{conn: conn, pod: pod, user: user} do

      assert conn.assigns.pod.id == pod.id
      assert conn.assigns.current_user.id == user.id
    end

    test "sets the user session", %{conn: conn, pod: pod, user: user} do
      pod_id = Integer.to_string(pod.id)

      %{^pod_id => [user_id | _]} =
        conn
        |> get_session(:sessions)
        |> Poison.decode!

      assert user_id == user.id
    end
  end

  describe "sign_out/2" do
    test "signs out of the given pod only", %{conn: conn} do
      pod1 = %Bridge.Pod{id: 1}
      pod2 = %Bridge.Pod{id: 2}

      user1 = %Bridge.User{id: 1}
      user2 = %Bridge.User{id: 2}

      sign_out_conn =
        conn
        |> UserAuth.sign_in(pod1, user1)
        |> UserAuth.sign_in(pod2, user2)
        |> UserAuth.sign_out(pod1)
        |> send_resp(:ok, "")

      next_conn = get(sign_out_conn, "/")

      sessions =
        next_conn
        |> get_session(:sessions)
        |> Poison.decode!

      refute Map.has_key?(sessions, "1")
      assert Map.has_key?(sessions, "2")
    end
  end

  describe "sign_in_with_credentials/5" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{pod: pod, user: user}} = insert_signup(%{password: password})
      {:ok, %{conn: conn, pod: pod, user: user, password: password}}
    end

    test "signs in user with username credentials",
      %{conn: conn, pod: pod, user: user, password: password} do

      {:ok, conn} =
        UserAuth.sign_in_with_credentials(conn, pod, user.username, password, repo: Repo)

      assert conn.assigns.current_user.id == user.id
    end

    test "signs in user with email credentials",
      %{conn: conn, pod: pod, user: user, password: password} do

      {:ok, conn} =
        UserAuth.sign_in_with_credentials(conn, pod, user.email, password, repo: Repo)

      assert conn.assigns.current_user.id == user.id
    end

    test "returns unauthorized if password does not match",
      %{conn: conn, pod: pod, user: user} do

      {:error, :unauthorized, _conn} =
        UserAuth.sign_in_with_credentials(conn, pod, user.email, "wrongo", repo: Repo)
    end

    test "returns unauthorized if user is not found",
      %{conn: conn, pod: pod} do

      {:error, :not_found, _conn} =
        UserAuth.sign_in_with_credentials(conn, pod, "foo@bar.co", "wrongo", repo: Repo)
    end
  end

  defp to_user_session(pod, user, ts \\ 123) do
    Poison.encode!(%{Integer.to_string(pod.id) => [user.id, ts]})
  end
end
