defmodule LevelWeb.API.SpaceControllerTest do
  use LevelWeb.ConnCase, async: true

  alias LevelWeb.API.SpaceView

  describe "POST /api/spaces with valid data" do
    setup %{conn: conn} do
      params = valid_signup_params()

      conn =
        conn
        |> put_launch_host()
        |> put_req_header("content-type", "application/json")
        |> post("/api/spaces", %{signup: params})

      {:ok, %{conn: conn, params: params}}
    end

    test "creates new space", %{params: %{slug: slug}} do
      assert Repo.get_by!(Level.Spaces.Space, %{slug: slug})
    end

    test "creates new user as the owner of the space", %{params: %{slug: slug, email: email}} do
      user = Repo.get_by!(Level.Spaces.User, %{email: email})
      space = user |> Ecto.assoc(:space) |> Repo.one()

      assert user.email == email
      assert space.slug == slug
      assert user.role == "OWNER"
    end

    test "sign the user in", %{conn: conn, params: %{email: email}} do
      user = Repo.get_by!(Level.Spaces.User, %{email: email})
      assert conn.assigns.current_user.id == user.id
    end

    test "returns a created response", %{conn: conn, params: %{email: email}} do
      user = Repo.get_by!(Level.Spaces.User, %{email: email})
      space = user |> Ecto.assoc(:space) |> Repo.one()

      redirect_url = threads_url(conn, space)

      assert json_response(conn, 201) ==
               render_json(
                 SpaceView,
                 "create.json",
                 space: space,
                 user: user,
                 redirect_url: redirect_url
               )
    end
  end

  describe "POST /api/spaces with invalid data" do
    setup %{conn: conn} do
      params = %{email: "foobar", slug: "boo", space_name: "Foo"}
      user_count = count_all(Level.Spaces.User)
      space_count = count_all(Level.Spaces.Space)

      conn =
        conn
        |> put_launch_host()
        |> put_req_header("content-type", "application/json")
        |> post("/api/spaces", %{signup: params})

      {:ok, %{conn: conn, user_count: user_count, space_count: space_count}}
    end

    test "does not not create a new space", %{space_count: space_count} do
      assert space_count == count_all(Level.Spaces.Space)
    end

    test "does not not create a new user", %{user_count: user_count} do
      assert user_count == count_all(Level.Spaces.User)
    end

    test "returns a 422 response", %{conn: conn} do
      assert json_response(conn, 422)
    end
  end

  defp count_all(model) do
    Repo.all(from r in model, select: count(r.id))
  end
end
