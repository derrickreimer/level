defmodule LevelWeb.OpenInvitationControllerTest do
  use LevelWeb.ConnCase, async: true

  describe "GET /join/:id" do
    setup %{conn: conn} do
      {:ok, %{open_invitation: invitation}} = create_user_and_space(%{}, %{name: "Acme"})
      {:ok, %{conn: conn, invitation: invitation}}
    end

    test "renders the invitation if found", %{conn: conn, invitation: invitation} do
      conn =
        conn
        |> get("/join/#{invitation.token}")

      assert html_response(conn, 200) =~ "Join the Acme space"
    end

    test "renders 404 if invitation is revoked", %{conn: conn, invitation: invitation} do
      {:ok, _revoked_invitation} =
        invitation
        |> Ecto.Changeset.change(state: "REVOKED")
        |> Repo.update()

      conn =
        conn
        |> get("/join/#{invitation.token}")

      assert html_response(conn, 404)
    end

    test "renders 404 if invitation is not found", %{conn: conn} do
      conn =
        conn
        |> get("/join/idontexist")

      assert html_response(conn, 404)
    end
  end
end
