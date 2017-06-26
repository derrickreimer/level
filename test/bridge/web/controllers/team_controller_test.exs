defmodule Bridge.Web.TeamControllerTest do
  use Bridge.Web.ConnCase

  describe "GET /teams/new" do
    test "includes the correct headline", %{conn: conn} do
      conn = get conn, "/teams/new"
      assert html_response(conn, 200) =~ "Sign up for Bridge"
    end
  end

  describe "POST /teams with valid data" do
    setup %{conn: conn} do
      params = valid_signup_params()
      conn = post conn, "/teams", %{signup: params}
      {:ok, %{conn: conn, params: params}}
    end

    test "creates new team", %{params: %{slug: slug}} do
      assert Repo.get_by!(Bridge.Team, %{slug: slug})
    end

    test "creates new user as the owner of the team",
      %{params: %{slug: slug, email: email}} do

      user = Repo.get_by!(Bridge.User, %{email: email})
      team = Ecto.assoc(user, :team) |> Repo.one

      assert user.email == email
      assert team.slug == slug
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

  describe "POST /teams with invalid data" do
    setup %{conn: conn} do
      params = %{email: "foobar", slug: "boo", team_name: "Foo"}
      user_count = count_all(Bridge.User)
      team_count = count_all(Bridge.Team)
      conn = post conn, "/teams", %{signup: params}
      {:ok, %{conn: conn, user_count: user_count, team_count: team_count}}
    end

    test "does not not create a new team", %{team_count: team_count} do
      assert team_count == count_all(Bridge.Team)
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
