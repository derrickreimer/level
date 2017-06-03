defmodule Bridge.PodControllerTest do
  use Bridge.ConnCase

  describe "GET /pods/new" do
    test "includes the correct headline", %{conn: conn} do
      conn = get conn, "/pods/new"
      assert html_response(conn, 200) =~ "Sign up for Bridge"
    end
  end

  describe "POST /pods with valid data" do
    setup %{conn: conn} do
      params = valid_signup_params()
      conn = post conn, "/pods", %{signup: params}
      {:ok, %{conn: conn, params: params}}
    end

    test "creates new pod", %{params: %{slug: slug}} do
      assert Repo.get_by!(Bridge.Pod, %{slug: slug})
    end

    test "creates new user as the owner of the pod",
      %{params: %{slug: slug, email: email}} do

      user = Repo.get_by!(Bridge.User, %{email: email})
      pod = Ecto.assoc(user, :pod) |> Repo.one

      assert user.email == email
      assert pod.slug == slug
      assert user.role == 0
    end

    test "sign the user in", %{conn: conn, params: %{email: email}} do
      user = Repo.get_by!(Bridge.User, %{email: email})
      assert conn.assigns.current_user.id == user.id
    end

    test "redirects to the threads index",
      %{conn: conn, params: %{slug: slug}} do

      assert redirected_to(conn) == "/#{slug}"
    end
  end

  describe "POST /pods with invalid data" do
    setup %{conn: conn} do
      params = %{email: "foobar", slug: "boo", pod_name: "Foo"}
      user_count = count_all(Bridge.User)
      pod_count = count_all(Bridge.Pod)
      conn = post conn, "/pods", %{signup: params}
      {:ok, %{conn: conn, user_count: user_count, pod_count: pod_count}}
    end

    test "does not not create a new pod", %{pod_count: pod_count} do
      assert pod_count == count_all(Bridge.Pod)
    end

    test "does not not create a new user", %{user_count: user_count} do
      assert user_count == count_all(Bridge.User)
    end

    test "renders the form with errors", %{conn: conn} do
      assert html_response(conn, 200) =~ "is invalid"
    end
  end

  defp count_all(model) do
    Repo.all(from r in model, select: count(r.id))
  end
end
