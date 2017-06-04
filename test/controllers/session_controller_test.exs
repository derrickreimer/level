defmodule Bridge.SessionControllerTest do
  use Bridge.ConnCase

  describe "GET /:pod_id/signin" do
    test "includes the correct heading", %{conn: conn} do
      {:ok, %{pod: pod}} = insert_signup()
      conn = get conn, "/#{pod.slug}/signin"
      assert html_response(conn, 200) =~ "Sign in to Bridge"
    end
  end

  describe "POST /:pod_id/signin" do
    setup %{conn: conn} do
      password = "$ecret$"

      {:ok, %{user: user, pod: pod}} =
        insert_signup(%{password: password})

      {:ok, %{conn: conn, user: user, pod: pod, password: password}}
    end

    test "signs in the user by username",
      %{conn: conn, user: user, pod: pod, password: password} do

      conn = post conn, "/#{pod.slug}/signin",
        %{"session" => %{"username" => user.username, "password" => password}}

      assert conn.assigns.current_user.id == user.id
      assert redirected_to(conn, 302) =~ "/#{pod.slug}"
    end

    test "signs in the user by email",
      %{conn: conn, user: user, pod: pod, password: password} do

      conn = post conn, "/#{pod.slug}/signin",
        %{"session" => %{"username" => user.email, "password" => password}}

      assert conn.assigns.current_user.id == user.id
      assert redirected_to(conn, 302) =~ "/#{pod.slug}"
    end

    test "renders an error with invalid credentials",
      %{conn: conn, user: user, pod: pod} do

      conn = post conn, "/#{pod.slug}/signin",
        %{"session" => %{"username" => user.email, "password" => "wrong"}}

      assert conn.assigns.current_user == nil
      assert html_response(conn, 200) =~ "Oops, those credentials are not correct"
    end
  end
end
