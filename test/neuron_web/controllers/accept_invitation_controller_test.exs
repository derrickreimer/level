defmodule NeuronWeb.AcceptInvitationControllerTest do
  use NeuronWeb.ConnCase

  alias Neuron.Teams

  setup %{conn: conn} do
    {:ok, %{team: team, user: owner}} = insert_signup()

    conn =
      conn
      |> put_team_host(team)

    {:ok, %{conn: conn, team: team, owner: owner}}
  end

  describe "POST /invitations/:id/accept" do
    setup %{conn: conn, team: team, owner: owner} do
      changeset =
        %{team: team, invitor: owner}
        |> valid_invitation_params()
        |> Teams.create_invitation_changeset()

      {:ok, invitation} = Teams.create_invitation(changeset)
      {:ok, %{conn: conn, team: team, invitor: owner, invitation: invitation}}
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
