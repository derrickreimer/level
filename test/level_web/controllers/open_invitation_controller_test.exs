defmodule LevelWeb.OpenInvitationControllerTest do
  use LevelWeb.ConnCase, async: true

  alias Level.Spaces
  alias Level.Users.User

  describe "GET /invites/:id" do
    setup %{conn: conn} do
      {:ok, result} = create_user_and_space(%{}, %{name: "Acme"})
      {:ok, Map.put(result, :conn, conn)}
    end

    test "renders the invitation if found", %{conn: conn, open_invitation: invitation} do
      conn =
        conn
        |> get("/invites/#{invitation.token}")

      assert html_response(conn, 200) =~ "Join the Acme space"
    end

    test "renders 404 if invitation is revoked", %{conn: conn, open_invitation: invitation} do
      {:ok, _revoked_invitation} =
        invitation
        |> Ecto.Changeset.change(state: "REVOKED")
        |> Repo.update()

      conn =
        conn
        |> get("/invites/#{invitation.token}")

      assert html_response(conn, 404)
    end

    test "renders 404 if invitation is not found", %{conn: conn} do
      conn =
        conn
        |> get("/invites/idontexist")

      assert html_response(conn, 404)
    end

    test "renders accept form if logged in", %{conn: conn, open_invitation: invitation} do
      {:ok, user} = create_user()

      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/")
        |> sign_in(user)
        |> get("/invites/#{invitation.token}")

      assert html_response(conn, 200) =~ "Let’s go!"
    end

    test "redirects if user is already a member", %{
      conn: conn,
      open_invitation: invitation,
      space: space,
      user: user
    } do
      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/")
        |> sign_in(user)
        |> get("/invites/#{invitation.token}")

      assert redirected_to(conn, 302) =~ "/#{space.slug}"
    end
  end

  describe "/invites/:id/accept" do
    setup %{conn: conn} do
      {:ok, result} = create_user_and_space(%{}, %{name: "Acme", slug: "acme"})
      {:ok, Map.put(result, :conn, conn)}
    end

    test "signs up new users and creates a membership", %{
      conn: conn,
      space: space,
      open_invitation: invitation
    } do
      params =
        valid_user_params()
        |> Map.put(:email, "derrick@level.app")

      conn =
        conn
        |> post("/invites/#{invitation.token}/accept", %{signup: params})

      assert redirected_to(conn, 302) =~ "/acme"

      # verify the newly-created user is a member of the space
      user = Repo.get_by(User, email: "derrick@level.app")
      {:ok, %{space_user: space_user}} = Spaces.get_space(user, space.id)
      assert space_user.role == "MEMBER"
    end

    test "creates a membership for the currently logged in user", %{
      conn: conn,
      space: space,
      open_invitation: invitation
    } do
      {:ok, user} = create_user()

      conn =
        conn
        |> bypass_through(LevelWeb.Router, :anonymous_browser)
        |> get("/")
        |> sign_in(user)
        |> post("/invites/#{invitation.token}/accept")

      assert redirected_to(conn, 302) =~ "/acme"

      {:ok, %{space_user: space_user}} = Spaces.get_space(user, space.id)
      assert space_user.role == "MEMBER"
    end
  end
end
