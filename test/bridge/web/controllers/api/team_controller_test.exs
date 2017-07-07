defmodule Bridge.Web.API.TeamControllerTest do
  use Bridge.Web.ConnCase

  alias Bridge.Web.API.TeamView

  describe "POST /api/teams with valid data" do
    setup %{conn: conn} do
      params = valid_signup_params()

      conn =
        conn
        |> put_launch_host()
        |> put_req_header("content-type", "application/json")
        |> post("/api/teams", %{signup: params})

      {:ok, %{conn: conn, params: params}}
    end

    test "creates new team", %{params: %{slug: slug}} do
      assert Repo.get_by!(Bridge.Team, %{slug: slug})
    end

    test "creates new user as the owner of the team",
      %{params: %{slug: slug, email: email}} do

      user = Repo.get_by!(Bridge.User, %{email: email})
      team = user |> Ecto.assoc(:team) |> Repo.one

      assert user.email == email
      assert team.slug == slug
      assert user.role == 0
    end

    test "sign the user in", %{conn: conn, params: %{email: email}} do
      user = Repo.get_by!(Bridge.User, %{email: email})
      assert conn.assigns.current_user.id == user.id
    end

    test "returns a created response",
      %{conn: conn, params: %{email: email}} do

      user = Repo.get_by!(Bridge.User, %{email: email})
      team = user |> Ecto.assoc(:team) |> Repo.one

      redirect_url = threads_url(conn, team)

      assert json_response(conn, 201) ==
        render_json(TeamView, "create.json", team: team, user: user, redirect_url: redirect_url)
    end
  end

  describe "POST /api/teams with invalid data" do
    setup %{conn: conn} do
      params = %{email: "foobar", slug: "boo", team_name: "Foo"}
      user_count = count_all(Bridge.User)
      team_count = count_all(Bridge.Team)

      conn =
        conn
        |> put_launch_host()
        |> put_req_header("content-type", "application/json")
        |> post("/api/teams", %{signup: params})

      {:ok, %{conn: conn, user_count: user_count, team_count: team_count}}
    end

    test "does not not create a new team", %{team_count: team_count} do
      assert team_count == count_all(Bridge.Team)
    end

    test "does not not create a new user", %{user_count: user_count} do
      assert user_count == count_all(Bridge.User)
    end

    test "returns a 422 response", %{conn: conn} do
      assert json_response(conn, 422)
    end
  end

  defp count_all(model) do
    Repo.all(from r in model, select: count(r.id))
  end
end
