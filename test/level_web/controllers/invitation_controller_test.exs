defmodule LevelWeb.InvitationControllerTest do
  use LevelWeb.ConnCase, async: true

  # alias Level.Spaces.Invitation
  alias Level.Spaces

  setup %{conn: conn} do
    {:ok, %{space: space, user: owner}} = insert_signup()

    conn =
      conn
      |> put_space_host(space)

    {:ok, %{conn: conn, space: space, owner: owner}}
  end

  describe "GET /invitations/:id" do
    setup %{conn: conn, space: space, owner: owner} do
      params = valid_invitation_params()
      {:ok, invitation} = Spaces.create_invitation(owner, params)
      {:ok, %{conn: conn, space: space, invitor: owner, invitation: invitation}}
    end

    test "displays the correct copy", %{
      conn: conn,
      space: space,
      invitor: invitor,
      invitation: invitation
    } do
      conn =
        conn
        |> get("/invitations/#{invitation.token}")

      response = html_response(conn, 200)
      assert response =~ "Join #{space.name} on Level"
      assert response =~ "You were invited by #{invitor.email}"
    end

    test "returns a 404 if invitation does not exist", %{conn: conn} do
      assert_raise(Ecto.NoResultsError, fn ->
        conn
        |> get("/invitations/#{Ecto.UUID.generate()}")
      end)
    end
  end
end
