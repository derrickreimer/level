defmodule Bridge.SessionControllerTest do
  use Bridge.ConnCase

  describe "GET /:pod_id/login" do
    test "includes the correct heading", %{conn: conn} do
      {:ok, %{pod: pod}} = insert_signup()
      conn = get conn, "/#{pod.slug}/login"
      assert html_response(conn, 200) =~ "Sign in to Bridge"
    end

    test "redirects to threads path if already signed in", %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, pod: pod}} = insert_signup(%{password: password})

      signed_in_conn = post conn, "/#{pod.slug}/login",
        %{"session" => %{"username" => user.username, "password" => password}}

      conn = get signed_in_conn, "/#{pod.slug}/login"
      assert redirected_to(conn, 302) =~ "/#{pod.slug}"
    end
  end

  describe "POST /:pod_id/login" do
    setup %{conn: conn} do
      password = "$ecret$"
      {:ok, %{user: user, pod: pod}} = insert_signup(%{password: password})
      {:ok, %{conn: conn, user: user, pod: pod, password: password}}
    end

    test "signs in the user by username",
      %{conn: conn, user: user, pod: pod, password: password} do

      conn = post conn, "/#{pod.slug}/login",
        %{"session" => %{"username" => user.username, "password" => password}}

      assert conn.assigns.current_user.id == user.id
      assert redirected_to(conn, 302) =~ "/#{pod.slug}"
    end

    test "signs in the user by email",
      %{conn: conn, user: user, pod: pod, password: password} do

      conn = post conn, "/#{pod.slug}/login",
        %{"session" => %{"username" => user.email, "password" => password}}

      assert conn.assigns.current_user.id == user.id
      assert redirected_to(conn, 302) =~ "/#{pod.slug}"
    end

    test "renders an error with invalid credentials",
      %{conn: conn, user: user, pod: pod} do

      conn = post conn, "/#{pod.slug}/login",
        %{"session" => %{"username" => user.email, "password" => "wrong"}}

      assert conn.assigns.current_user == nil
      assert html_response(conn, 200) =~ "Oops, those credentials are not correct"
    end
  end
end
