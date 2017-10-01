defmodule LevelWeb.AcceptInvitationControllerTest do
  use LevelWeb.ConnCase

  alias Level.Spaces

  setup %{conn: conn} do
    {:ok, %{space: space, user: owner}} = insert_signup()

    conn =
      conn
      |> put_space_host(space)

    {:ok, %{conn: conn, space: space, owner: owner}}
  end

  describe "POST /invitations/:id/accept" do
    setup %{conn: conn, space: space, owner: owner} do
      changeset =
        %{space: space, invitor: owner}
        |> valid_invitation_params()
        |> Spaces.create_invitation_changeset()

      {:ok, invitation} = Spaces.create_invitation(changeset)
      {:ok, %{conn: conn, space: space, invitor: owner, invitation: invitation}}
    end

    test "signs in and redirects the user",
      %{conn: conn, invitation: invitation} do
      params = valid_user_params()

      conn =
        conn
        |> post("/invitations/#{invitation.token}/accept", %{"user" => params})

      assert redirected_to(conn, 302) =~ "/"
      assert conn.assigns[:current_user]
    end

    test "renders validation errors",
      %{conn: conn, invitation: invitation} do
      params =
        valid_user_params()
        |> Map.put(:username, "i am not valid")

      conn =
        conn
        |> post("/invitations/#{invitation.token}/accept", %{"user" => params})

      assert html_response(conn, 200) =~ "must be lowercase and alphanumeric"
    end
  end
end
